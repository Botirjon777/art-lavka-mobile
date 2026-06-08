import { Injectable } from '@nestjs/common';
import { OrderStatus, Prisma } from '@prisma/client';
import { AppException } from '../common/errors/app.exception';
import { ErrorCode } from '../common/errors/error-codes';
import { assertOwnership } from '../common/ownership';
import { AppConstants } from '../config/constants';
import { LedgerService } from '../ledger/ledger.service';
import { PrismaService } from '../prisma/prisma.service';
import { CreateOrderDto } from './dto/create-order.dto';

const ORDER_INCLUDE = { items: true } satisfies Prisma.OrderInclude;
type OrderRow = Prisma.OrderGetPayload<{ include: typeof ORDER_INCLUDE }>;

export interface PaymentIntent {
  orderId: string;
  provider: string;
  checkoutUrl: string;
  amount: bigint;
}

@Injectable()
export class OrdersService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly ledger: LedgerService,
  ) {}

  /**
   * The price authority (BACKEND_NODE.md §5). Recomputes every price from the
   * CURRENT listing — never trusts a client price — snapshots base/royalty/
   * designer onto each item, creates the order, and returns a payment intent.
   */
  async createOrder(
    userId: string,
    dto: CreateOrderDto,
  ): Promise<{ order: OrderRow; intent: PaymentIntent }> {
    const ids = [...new Set(dto.items.map((i) => i.listingId))];
    const listings = await this.prisma.listing.findMany({
      where: { id: { in: ids } },
      include: {
        productType: { select: { baseCost: true } },
        design: {
          select: {
            id: true,
            title: true,
            previewUrl: true,
            designerId: true,
            status: true,
          },
        },
      },
    });
    const byId = new Map(listings.map((l) => [l.id, l]));

    let subtotal = 0n;
    const itemsData: Prisma.OrderItemCreateWithoutOrderInput[] = [];
    for (const line of dto.items) {
      const listing = byId.get(line.listingId);
      if (!listing || !listing.active || listing.design.status !== 'approved') {
        throw new AppException(
          ErrorCode.cartItemUnavailable,
          'An item in your cart is no longer available',
          409,
        );
      }
      const unitBaseCost = listing.productType.baseCost;
      const unitRoyalty = listing.royalty;
      subtotal += (unitBaseCost + unitRoyalty) * BigInt(line.quantity);
      itemsData.push({
        listing: { connect: { id: listing.id } },
        design: { connect: { id: listing.design.id } },
        designerId: listing.design.designerId,
        productType: { connect: { id: listing.productTypeId } },
        quantity: line.quantity,
        unitBaseCost,
        unitRoyalty,
        titleSnapshot: listing.design.title,
        mockupUrlSnapshot: listing.design.previewUrl,
        size: line.size ?? null,
        color: line.color ?? null,
      });
    }

    const shipping = 0n; // flat-rate/shipping policy TBD; snapshotted on the order.
    const total = subtotal + shipping;

    const shippingAddress = await this.resolveAddress(userId, dto);

    const order = await this.prisma.order.create({
      data: {
        customerId: userId,
        status: OrderStatus.pending,
        subtotal,
        shipping,
        total,
        paymentProvider: dto.paymentProvider,
        addressId: dto.addressId ?? null,
        shippingAddress,
        items: { create: itemsData },
      },
      include: ORDER_INCLUDE,
    });

    // TODO: create a real provider checkout session (Click/Payme/Uzum) and
    // return its hosted URL. Stubbed until provider credentials are wired.
    const intent: PaymentIntent = {
      orderId: order.id,
      provider: dto.paymentProvider,
      checkoutUrl: `https://pay.example/${dto.paymentProvider}/${order.id}`,
      amount: total,
    };

    return { order, intent };
  }

  /** A page of the caller's orders (ownership scoped by the where clause). */
  async myOrders(userId: string, page = 0) {
    const pageSize = AppConstants.pageSize;
    const where: Prisma.OrderWhereInput = { customerId: userId };
    const [rows, total] = await Promise.all([
      this.prisma.order.findMany({
        where,
        include: ORDER_INCLUDE,
        orderBy: { createdAt: 'desc' },
        skip: page * pageSize,
        take: pageSize,
      }),
      this.prisma.order.count({ where }),
    ]);
    return {
      data: rows.map((o) => this.toJson(o)),
      page,
      pageSize,
      total,
    };
  }

  /** One order, only if it belongs to the caller. */
  async order(userId: string, id: string) {
    const order = await this.prisma.order.findUnique({
      where: { id },
      include: ORDER_INCLUDE,
    });
    if (!order) throw AppException.notFound('Order not found');
    assertOwnership(userId, order.customerId, 'This order is not yours');
    return this.toJson(order);
  }

  /** Ops-only status advance (production → shipped → delivered, …). */
  async updateStatus(id: string, status: OrderStatus) {
    const order = await this.prisma.order.findUnique({ where: { id } });
    if (!order) throw AppException.notFound('Order not found');
    const updated = await this.prisma.order.update({
      where: { id },
      data: {
        status,
        ...(status === OrderStatus.delivered
          ? { deliveredAt: new Date() }
          : {}),
      },
      include: ORDER_INCLUDE,
    });
    // Refund → reverse any accrued royalties for this order (BACKEND_NODE.md §5).
    if (status === OrderStatus.refunded) {
      await this.ledger.clawbackForOrder(id);
    }
    return this.toJson(updated);
  }

  private async resolveAddress(
    userId: string,
    dto: CreateOrderDto,
  ): Promise<string | null> {
    if (dto.addressId) {
      const address = await this.prisma.address.findUnique({
        where: { id: dto.addressId },
        select: { userId: true, line: true, city: true },
      });
      if (!address) throw AppException.notFound('Address not found');
      assertOwnership(userId, address.userId, 'This address is not yours');
      return [address.line, address.city].filter(Boolean).join(', ');
    }
    return dto.shippingAddress ?? null;
  }

  /** Shape an order for the API: items under `orderItems` (→ `order_items`). */
  private toJson(order: OrderRow) {
    const { items, ...rest } = order;
    return { ...rest, orderItems: items };
  }
}
