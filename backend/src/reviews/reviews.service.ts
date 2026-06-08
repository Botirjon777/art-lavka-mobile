import { Injectable } from '@nestjs/common';
import { OrderStatus } from '@prisma/client';
import { AppException } from '../common/errors/app.exception';
import { ErrorCode } from '../common/errors/error-codes';
import { assertOwnership } from '../common/ownership';
import { PrismaService } from '../prisma/prisma.service';
import { CreateReviewDto } from './dto/create-review.dto';

@Injectable()
export class ReviewsService {
  constructor(private readonly prisma: PrismaService) {}

  /** One review per delivered order item, by its owner. */
  async create(userId: string, dto: CreateReviewDto) {
    const item = await this.prisma.orderItem.findUnique({
      where: { id: dto.orderItemId },
      select: {
        order: { select: { customerId: true, status: true } },
        review: { select: { id: true } },
      },
    });
    if (!item) throw AppException.notFound('Order item not found');
    assertOwnership(userId, item.order.customerId, 'This item is not yours');
    if (item.order.status !== OrderStatus.delivered) {
      throw new AppException(
        ErrorCode.validation,
        'You can only review delivered items',
        422,
      );
    }
    if (item.review) {
      throw new AppException(
        ErrorCode.validation,
        'This item has already been reviewed',
        409,
      );
    }

    const [review] = await this.prisma.$transaction([
      this.prisma.review.create({
        data: {
          orderItemId: dto.orderItemId,
          customerId: userId,
          rating: dto.rating,
          comment: dto.comment ?? null,
        },
      }),
      this.prisma.orderItem.update({
        where: { id: dto.orderItemId },
        data: { reviewed: true },
      }),
    ]);
    return review;
  }
}
