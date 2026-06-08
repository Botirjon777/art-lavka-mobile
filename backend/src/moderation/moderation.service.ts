import { Injectable } from '@nestjs/common';
import { DesignStatus } from '@prisma/client';
import { AppException } from '../common/errors/app.exception';
import { AppConstants } from '../config/constants';
import { PrismaService } from '../prisma/prisma.service';
import { ModerationDecisionDto } from './dto/moderation-decision.dto';

/**
 * Moderation queue (BACKEND_NODE.md §5). Reviewers approve/reject designs,
 * enforcing the content rules (no 18+, religion, war, IP) by judgment; this
 * service records the decision and surfaces a rejection reason to the designer.
 */
@Injectable()
export class ModerationService {
  constructor(private readonly prisma: PrismaService) {}

  /** Pending designs awaiting review, oldest first (FIFO). */
  async queue(page = 0) {
    const pageSize = AppConstants.pageSize;
    const where = { status: DesignStatus.pending };
    const [rows, total] = await Promise.all([
      this.prisma.design.findMany({
        where,
        orderBy: { createdAt: 'asc' },
        skip: page * pageSize,
        take: pageSize,
        include: {
          designer: {
            select: { designerProfile: { select: { displayName: true } } },
          },
        },
      }),
      this.prisma.design.count({ where }),
    ]);
    const data = rows.map(({ designer, ...d }) => ({
      ...d,
      designerName: designer.designerProfile?.displayName ?? '',
    }));
    return { data, page, pageSize, total };
  }

  async decide(designId: string, dto: ModerationDecisionDto) {
    const design = await this.prisma.design.findUnique({
      where: { id: designId },
      select: { id: true },
    });
    if (!design) throw AppException.notFound('Design not found');

    const approve = dto.decision === 'approve';
    return this.prisma.design.update({
      where: { id: designId },
      data: {
        status: approve ? DesignStatus.approved : DesignStatus.rejected,
        rejectionReason: approve ? null : (dto.reason ?? 'Not approved'),
      },
    });
  }
}
