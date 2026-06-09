import { Injectable } from '@nestjs/common';
import { KycStatus, OrderStatus, Prisma, UserRole } from '@prisma/client';
import { AppException } from '../common/errors/app.exception';
import { AppConstants } from '../config/constants';
import { PrismaService } from '../prisma/prisma.service';

/** Orders considered "real revenue" (past payment). */
const PAID_STATUSES = [
  OrderStatus.paid,
  OrderStatus.inProduction,
  OrderStatus.shipped,
  OrderStatus.delivered,
];

/**
 * Admin/moderation read + actions for the web panel. Everything here is behind
 * `@Roles('admin','moderator')` at the controller.
 */
@Injectable()
export class AdminService {
  constructor(private readonly prisma: PrismaService) {}

  /** Headline counts + revenue for the dashboard. */
  async stats() {
    const [customers, designers, pending, orders, paidOrders, revenue] =
      await Promise.all([
        this.prisma.user.count({ where: { role: UserRole.customer } }),
        this.prisma.designerProfile.count({
          where: { kycStatus: KycStatus.verified },
        }),
        this.prisma.designerProfile.count({
          where: { kycStatus: KycStatus.pending },
        }),
        this.prisma.order.count(),
        this.prisma.order.count({ where: { status: { in: PAID_STATUSES } } }),
        this.prisma.order.aggregate({
          _sum: { total: true },
          where: { status: { in: PAID_STATUSES } },
        }),
      ]);
    return {
      customers,
      designers,
      pendingApplications: pending,
      orders,
      paidOrders,
      revenueUzs: revenue._sum.total ?? 0n,
    };
  }

  /** Designer profiles (optionally filtered by KYC status), newest first. */
  async designers(status: KycStatus | undefined, page = 0) {
    const pageSize = AppConstants.pageSize;
    const where: Prisma.DesignerProfileWhereInput = status
      ? { kycStatus: status }
      : {};
    const [rows, total] = await Promise.all([
      this.prisma.designerProfile.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip: page * pageSize,
        take: pageSize,
        include: {
          user: { select: { phone: true, email: true, fullName: true } },
        },
      }),
      this.prisma.designerProfile.count({ where }),
    ]);
    return {
      data: rows.map(({ user, ...p }) => ({ ...p, ...user })),
      page,
      pageSize,
      total,
    };
  }

  /** One designer profile + their portfolio/earnings stats. */
  async designerDetail(userId: string) {
    const profile = await this.prisma.designerProfile.findUnique({
      where: { userId },
      include: {
        user: { select: { phone: true, email: true, fullName: true } },
      },
    });
    if (!profile) throw AppException.notFound('Designer not found');

    const [designs, listings, sales, balance] = await Promise.all([
      this.prisma.design.count({ where: { designerId: userId } }),
      this.prisma.listing.count({ where: { design: { designerId: userId } } }),
      this.prisma.orderItem.count({ where: { designerId: userId } }),
      this.prisma.ledgerEntry.aggregate({
        _sum: { amount: true },
        where: { designerId: userId },
      }),
    ]);

    const { user, ...rest } = profile;
    return {
      ...rest,
      ...user,
      stats: {
        designs,
        listings,
        sales,
        balanceUzs: balance._sum.amount ?? 0n,
      },
    };
  }

  /** Approve a seller application → verified (unlocks the Studio dashboard). */
  async verify(userId: string) {
    await this.assertProfile(userId);
    return this.prisma.designerProfile.update({
      where: { userId },
      data: { kycStatus: KycStatus.verified },
    });
  }

  /** Reject a seller application → rejected (they can re-apply). */
  async reject(userId: string) {
    await this.assertProfile(userId);
    return this.prisma.designerProfile.update({
      where: { userId },
      data: { kycStatus: KycStatus.rejected },
    });
  }

  /** Customers with their order counts. */
  async customers(page = 0) {
    const pageSize = AppConstants.pageSize;
    const where: Prisma.UserWhereInput = { role: UserRole.customer };
    const [rows, total] = await Promise.all([
      this.prisma.user.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip: page * pageSize,
        take: pageSize,
        select: {
          id: true,
          fullName: true,
          phone: true,
          email: true,
          languageCode: true,
          createdAt: true,
          _count: { select: { orders: true } },
        },
      }),
      this.prisma.user.count({ where }),
    ]);
    return {
      data: rows.map(({ _count, ...u }) => ({
        ...u,
        orderCount: _count.orders,
      })),
      page,
      pageSize,
      total,
    };
  }

  private async assertProfile(userId: string) {
    const exists = await this.prisma.designerProfile.findUnique({
      where: { userId },
      select: { userId: true },
    });
    if (!exists) throw AppException.notFound('Designer not found');
  }
}
