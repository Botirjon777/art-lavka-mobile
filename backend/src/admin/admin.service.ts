import { Injectable } from '@nestjs/common';
import {
  DesignStatus,
  KycStatus,
  OrderStatus,
  Prisma,
  UserRole,
} from '@prisma/client';
import { AppException } from '../common/errors/app.exception';
import { ErrorCode } from '../common/errors/error-codes';
import { AppConstants } from '../config/constants';
import { PrismaService } from '../prisma/prisma.service';
import { UpdateListingDto } from '../designs/dto/update-listing.dto';

/** Orders considered "real revenue" (past payment). */
const PAID_STATUSES = [
  OrderStatus.paid,
  OrderStatus.inProduction,
  OrderStatus.shipped,
  OrderStatus.delivered,
];

/** Shared design include: shop name/slug, categories, and listing count. */
const DESIGN_INCLUDE = {
  designer: {
    select: {
      fullName: true,
      designerProfile: { select: { displayName: true, slug: true } },
    },
  },
  categories: { select: { categoryId: true } },
  _count: { select: { listings: true } },
} satisfies Prisma.DesignInclude;

type AdminDesign = Prisma.DesignGetPayload<{ include: typeof DESIGN_INCLUDE }>;
type AdminListing = Prisma.ListingGetPayload<{
  include: { productType: true };
}>;

/**
 * Admin/moderation read + actions for the web panel. Everything here is behind
 * `@Roles('admin','moderator')` at the controller.
 */
@Injectable()
export class AdminService {
  constructor(private readonly prisma: PrismaService) {}

  /** Headline counts + revenue for the dashboard. */
  async stats() {
    const [
      customers,
      designers,
      pending,
      pendingDesigns,
      orders,
      paidOrders,
      revenue,
    ] = await Promise.all([
      this.prisma.user.count({ where: { role: UserRole.customer } }),
      this.prisma.designerProfile.count({
        where: { kycStatus: KycStatus.verified },
      }),
      this.prisma.designerProfile.count({
        where: { kycStatus: KycStatus.pending },
      }),
      this.prisma.design.count({ where: { status: DesignStatus.pending } }),
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
      pendingDesigns,
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

  // ---- Design moderation -------------------------------------------------

  /** All designs (optionally by status), newest first, with shop + counts. */
  async designs(status: DesignStatus | undefined, page = 0) {
    const pageSize = AppConstants.pageSize;
    const where: Prisma.DesignWhereInput = status ? { status } : {};
    const [rows, total] = await Promise.all([
      this.prisma.design.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip: page * pageSize,
        take: pageSize,
        include: DESIGN_INCLUDE,
      }),
      this.prisma.design.count({ where }),
    ]);
    return {
      data: rows.map((d) => this.toAdminDesignJson(d)),
      page,
      pageSize,
      total,
    };
  }

  /** One design with its shop, categories, and listings (with product names). */
  async designDetail(id: string) {
    const design = await this.prisma.design.findUnique({
      where: { id },
      include: {
        ...DESIGN_INCLUDE,
        listings: { include: { productType: true } },
      },
    });
    if (!design) throw AppException.notFound('Design not found');
    const { listings, ...rest } = design;
    return {
      ...this.toAdminDesignJson(rest),
      listings: listings.map((l) => this.toListingJson(l)),
    };
  }

  /** Approve a print → visible in the catalog. */
  async approveDesign(id: string) {
    await this.assertDesign(id);
    return this.prisma.design.update({
      where: { id },
      data: { status: DesignStatus.approved, rejectionReason: null },
    });
  }

  /** Reject a print (optionally with a reason the seller will see). */
  async rejectDesign(id: string, reason?: string) {
    await this.assertDesign(id);
    return this.prisma.design.update({
      where: { id },
      data: {
        status: DesignStatus.rejected,
        rejectionReason: reason?.trim() || null,
      },
    });
  }

  /** Moderate a listing: toggle visibility / adjust royalty. */
  async setListing(listingId: string, dto: UpdateListingDto) {
    const listing = await this.prisma.listing.findUnique({
      where: { id: listingId },
      select: { id: true },
    });
    if (!listing) throw AppException.notFound('Listing not found');
    if (dto.royalty !== undefined) {
      const value = BigInt(dto.royalty);
      if (
        value < AppConstants.royaltyMinUzs ||
        value > AppConstants.royaltyMaxUzs
      ) {
        throw new AppException(
          ErrorCode.royaltyOutOfBounds,
          'Royalty is out of the allowed range',
          422,
        );
      }
    }
    const updated = await this.prisma.listing.update({
      where: { id: listingId },
      data: {
        ...(dto.royalty !== undefined ? { royalty: BigInt(dto.royalty) } : {}),
        ...(dto.active !== undefined ? { active: dto.active } : {}),
      },
      include: { productType: true },
    });
    return this.toListingJson(updated);
  }

  // ---- Shops -------------------------------------------------------------

  /** Every shop (designer profile), newest first, with portfolio counts. */
  async shops(status: KycStatus | undefined, page = 0) {
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
          user: {
            select: {
              phone: true,
              email: true,
              fullName: true,
              _count: { select: { designs: true } },
            },
          },
        },
      }),
      this.prisma.designerProfile.count({ where }),
    ]);
    return {
      data: rows.map(({ user, ...p }) => {
        const { _count, ...u } = user;
        return { ...p, ...u, designCount: _count.designs };
      }),
      page,
      pageSize,
      total,
    };
  }

  /** A single shop: profile + earnings stats + its designs (with statuses). */
  async shopDetail(userId: string) {
    const detail = await this.designerDetail(userId);
    const designs = await this.prisma.design.findMany({
      where: { designerId: userId },
      orderBy: { createdAt: 'desc' },
      include: DESIGN_INCLUDE,
    });
    return {
      ...detail,
      designs: designs.map((d) => this.toAdminDesignJson(d)),
    };
  }

  // ---- helpers -----------------------------------------------------------

  private toAdminDesignJson(d: AdminDesign) {
    const { designer, categories, _count, ...rest } = d;
    return {
      ...rest,
      shopName: designer.designerProfile?.displayName ?? designer.fullName,
      shopSlug: designer.designerProfile?.slug ?? null,
      categoryIds: categories.map((c) => c.categoryId),
      listingCount: _count.listings,
    };
  }

  private toListingJson(l: AdminListing) {
    const { productType, ...rest } = l;
    return {
      ...rest,
      productTypeName: productType.nameEn,
      productTypeSlug: productType.slug,
    };
  }

  private async assertDesign(id: string) {
    const exists = await this.prisma.design.findUnique({
      where: { id },
      select: { id: true },
    });
    if (!exists) throw AppException.notFound('Design not found');
  }

  private async assertProfile(userId: string) {
    const exists = await this.prisma.designerProfile.findUnique({
      where: { userId },
      select: { userId: true },
    });
    if (!exists) throw AppException.notFound('Designer not found');
  }
}
