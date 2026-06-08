import { Injectable } from '@nestjs/common';
import { DesignStatus, Prisma } from '@prisma/client';
import { AppException } from '../common/errors/app.exception';
import { ErrorCode } from '../common/errors/error-codes';
import { assertOwnership } from '../common/ownership';
import { AppConstants } from '../config/constants';
import { PrismaService } from '../prisma/prisma.service';
import { CreateDesignDto } from './dto/create-design.dto';
import { UpdateListingDto } from './dto/update-listing.dto';
import { UpsertListingDto } from './dto/upsert-listing.dto';

@Injectable()
export class DesignsService {
  constructor(private readonly prisma: PrismaService) {}

  /** Create a design (status pending → moderation). Files already presign-uploaded. */
  async createDesign(userId: string, dto: CreateDesignDto) {
    if (
      dto.widthPx < AppConstants.minPrintWidthPx ||
      dto.heightPx < AppConstants.minPrintHeightPx
    ) {
      throw new AppException(
        ErrorCode.uploadTooSmall,
        'Image is too small to print well',
        422,
      );
    }

    const design = await this.prisma.design.create({
      data: {
        designerId: userId,
        title: dto.title,
        description: dto.description ?? null,
        previewUrl: dto.previewUrl,
        printFilePath: dto.printFilePath,
        widthPx: dto.widthPx,
        heightPx: dto.heightPx,
        status: DesignStatus.pending,
        ...(dto.categoryIds && dto.categoryIds.length > 0
          ? {
              categories: {
                create: dto.categoryIds.map((categoryId) => ({ categoryId })),
              },
            }
          : {}),
      },
      include: { categories: { select: { categoryId: true } } },
    });
    return this.toDesignJson(design);
  }

  /** The caller's designs + statuses, newest first. */
  async myDesigns(userId: string, page = 0) {
    const pageSize = AppConstants.pageSize;
    const where: Prisma.DesignWhereInput = { designerId: userId };
    const [rows, total] = await Promise.all([
      this.prisma.design.findMany({
        where,
        include: { categories: { select: { categoryId: true } } },
        orderBy: { createdAt: 'desc' },
        skip: page * pageSize,
        take: pageSize,
      }),
      this.prisma.design.count({ where }),
    ]);
    return {
      data: rows.map((d) => this.toDesignJson(d)),
      page,
      pageSize,
      total,
    };
  }

  /** Create/update the listing (royalty/active) for a design on a product. */
  async upsertListing(userId: string, dto: UpsertListingDto) {
    await this.assertDesignOwner(userId, dto.designId);
    this.assertRoyaltyInBounds(dto.royalty);

    return this.prisma.listing.upsert({
      where: {
        designId_productTypeId: {
          designId: dto.designId,
          productTypeId: dto.productTypeId,
        },
      },
      create: {
        designId: dto.designId,
        productTypeId: dto.productTypeId,
        royalty: BigInt(dto.royalty),
        active: dto.active ?? true,
      },
      update: {
        royalty: BigInt(dto.royalty),
        ...(dto.active !== undefined ? { active: dto.active } : {}),
      },
    });
  }

  /** Update an existing listing's royalty/active (owner only). */
  async updateListing(
    userId: string,
    listingId: string,
    dto: UpdateListingDto,
  ) {
    const listing = await this.prisma.listing.findUnique({
      where: { id: listingId },
      select: { id: true, design: { select: { designerId: true } } },
    });
    if (!listing) throw AppException.notFound('Listing not found');
    assertOwnership(
      userId,
      listing.design.designerId,
      'This listing is not yours',
    );
    if (dto.royalty !== undefined) this.assertRoyaltyInBounds(dto.royalty);

    return this.prisma.listing.update({
      where: { id: listingId },
      data: {
        ...(dto.royalty !== undefined ? { royalty: BigInt(dto.royalty) } : {}),
        ...(dto.active !== undefined ? { active: dto.active } : {}),
      },
    });
  }

  private async assertDesignOwner(userId: string, designId: string) {
    const design = await this.prisma.design.findUnique({
      where: { id: designId },
      select: { designerId: true },
    });
    if (!design) throw AppException.notFound('Design not found');
    assertOwnership(userId, design.designerId, 'This design is not yours');
  }

  private assertRoyaltyInBounds(royalty: number) {
    const value = BigInt(royalty);
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

  private toDesignJson(
    design: Prisma.DesignGetPayload<{
      include: { categories: { select: { categoryId: true } } };
    }>,
  ) {
    const { categories, ...rest } = design;
    return { ...rest, categoryIds: categories.map((c) => c.categoryId) };
  }
}
