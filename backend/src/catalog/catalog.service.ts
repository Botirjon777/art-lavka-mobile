import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { AppException } from '../common/errors/app.exception';
import { AppConstants } from '../config/constants';
import { PrismaService } from '../prisma/prisma.service';
import { aggregateRatings, resolveOrderBy } from './catalog.mapper';

/** Fields needed to render a listing card (mirrors the `listing_cards` view). */
const CARD_INCLUDE = {
  productType: { select: { baseCost: true } },
  design: {
    select: {
      id: true,
      title: true,
      previewUrl: true,
      designerId: true,
      designer: {
        select: { designerProfile: { select: { displayName: true } } },
      },
      categories: { select: { category: { select: { slug: true } } } },
    },
  },
} satisfies Prisma.ListingInclude;

type CardRow = Prisma.ListingGetPayload<{ include: typeof CARD_INCLUDE }>;

export interface Paginated<T> {
  data: T[];
  page: number;
  pageSize: number;
  total: number;
}

@Injectable()
export class CatalogService {
  constructor(private readonly prisma: PrismaService) {}

  // --- Reference data (small, unpaginated) ----------------------------------

  categories() {
    return this.prisma.category.findMany({ orderBy: { sortOrder: 'asc' } });
  }

  productTypes() {
    return this.prisma.productType.findMany({ orderBy: { slug: 'asc' } });
  }

  banners() {
    return this.prisma.banner.findMany({
      where: { active: true },
      orderBy: { sortOrder: 'asc' },
    });
  }

  // --- Listings (catalog cards) ---------------------------------------------

  /** A page of active listings of approved designs, optionally filtered. */
  async listings(opts: {
    category?: string;
    q?: string;
    sort?: string;
    page?: number;
  }): Promise<Paginated<ReturnType<CatalogService['toCard']>>> {
    const page = opts.page ?? 0;
    const pageSize = AppConstants.pageSize;

    const where: Prisma.ListingWhereInput = {
      active: true,
      design: {
        status: 'approved',
        ...(opts.q ? { title: { contains: opts.q, mode: 'insensitive' } } : {}),
        ...(opts.category
          ? { categories: { some: { category: { slug: opts.category } } } }
          : {}),
      },
    };

    const [rows, total] = await Promise.all([
      this.prisma.listing.findMany({
        where,
        include: CARD_INCLUDE,
        orderBy: resolveOrderBy(opts.sort),
        skip: page * pageSize,
        take: pageSize,
      }),
      this.prisma.listing.count({ where }),
    ]);

    const ratings = await this.ratingsFor(rows.map((r) => r.design.id));
    return {
      data: rows.map((r) => this.toCard(r, ratings)),
      page,
      pageSize,
      total,
    };
  }

  search(q: string, page = 0) {
    return this.listings({ q, page });
  }

  /** Single listing detail for the product page (must be active + approved). */
  async listing(id: string) {
    const row = await this.prisma.listing.findFirst({
      where: { id, active: true, design: { status: 'approved' } },
      include: CARD_INCLUDE,
    });
    if (!row) throw AppException.notFound('Listing not found');
    const ratings = await this.ratingsFor([row.design.id]);
    return this.toCard(row, ratings);
  }

  /** A designer's public storefront: profile + their live listing cards. */
  async storefront(slug: string) {
    const profile = await this.prisma.designerProfile.findUnique({
      where: { slug },
      select: {
        userId: true,
        displayName: true,
        bio: true,
        avatarUrl: true,
        slug: true,
      },
    });
    if (!profile) throw AppException.notFound('Storefront not found');

    const rows = await this.prisma.listing.findMany({
      where: {
        active: true,
        design: { status: 'approved', designerId: profile.userId },
      },
      include: CARD_INCLUDE,
      orderBy: { createdAt: 'desc' },
    });
    const ratings = await this.ratingsFor(rows.map((r) => r.design.id));

    return {
      displayName: profile.displayName,
      bio: profile.bio,
      avatarUrl: profile.avatarUrl,
      slug: profile.slug,
      listings: rows.map((r) => this.toCard(r, ratings)),
    };
  }

  /** Reviews for a design (product page). Mirrors the `design_reviews` view. */
  async reviewsForDesign(designId: string) {
    const reviews = await this.prisma.review.findMany({
      where: { orderItem: { designId } },
      orderBy: { createdAt: 'desc' },
      select: {
        id: true,
        orderItemId: true,
        customerId: true,
        rating: true,
        comment: true,
        createdAt: true,
        customer: { select: { fullName: true } },
        orderItem: { select: { designId: true } },
      },
    });
    return reviews.map((r) => ({
      id: r.id,
      orderItemId: r.orderItemId,
      customerId: r.customerId,
      rating: r.rating,
      comment: r.comment,
      createdAt: r.createdAt,
      designId: r.orderItem.designId,
      customerName: r.customer.fullName,
    }));
  }

  // --- helpers ---------------------------------------------------------------

  private async ratingsFor(designIds: string[]) {
    if (designIds.length === 0) return aggregateRatings([]);
    const reviews = await this.prisma.review.findMany({
      where: { orderItem: { designId: { in: designIds } } },
      select: { rating: true, orderItem: { select: { designId: true } } },
    });
    return aggregateRatings(
      reviews.map((r) => ({
        designId: r.orderItem.designId,
        rating: r.rating,
      })),
    );
  }

  private toCard(
    row: CardRow,
    ratings: Map<string, { avg: number; count: number }>,
  ) {
    const rating = ratings.get(row.design.id) ?? { avg: 0, count: 0 };
    return {
      id: row.id,
      designId: row.designId,
      productTypeId: row.productTypeId,
      royalty: row.royalty,
      baseCost: row.productType.baseCost,
      active: row.active,
      createdAt: row.createdAt,
      title: row.design.title,
      designerName: row.design.designer.designerProfile?.displayName ?? '',
      // No server-rendered mockups yet → fall back to the design preview (§6).
      mockupUrl: row.design.previewUrl,
      ratingAvg: rating.avg,
      ratingCount: rating.count,
      categorySlugs: row.design.categories.map((c) => c.category.slug),
    };
  }
}
