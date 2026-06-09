import { Injectable } from '@nestjs/common';
import { KycStatus, UserRole } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { OnboardDto } from './dto/onboard.dto';

@Injectable()
export class DesignersService {
  constructor(private readonly prisma: PrismaService) {}

  /// The caller's designer profile, or null if they haven't onboarded.
  meProfile(userId: string) {
    return this.prisma.designerProfile.findUnique({ where: { userId } });
  }

  /// The caller's portfolio + earnings stats (Studio dashboard).
  async meStats(userId: string) {
    const [designs, listings, sales, balance] = await Promise.all([
      this.prisma.design.count({ where: { designerId: userId } }),
      this.prisma.listing.count({ where: { design: { designerId: userId } } }),
      this.prisma.orderItem.count({ where: { designerId: userId } }),
      this.prisma.ledgerEntry.aggregate({
        _sum: { amount: true },
        where: { designerId: userId },
      }),
    ]);
    return {
      designs,
      listings,
      sales,
      balanceUzs: balance._sum.amount ?? 0n,
    };
  }

  /**
   * Submit/refresh seller onboarding (SPEC §9). Records KYC + the accepted
   * contract version + regulations hash + typed signature, sets status to
   * `pending` (an admin verifies out-of-band), and promotes the user's role.
   */
  async onboard(userId: string, dto: OnboardDto) {
    const slug = `${this.slugify(dto.displayName)}-${userId.slice(0, 6)}`;
    const now = new Date();

    return this.prisma.$transaction(async (tx) => {
      const profile = await tx.designerProfile.upsert({
        where: { userId },
        create: {
          userId,
          slug,
          displayName: dto.displayName,
          legalName: dto.legalName,
          idNumber: dto.idNumber ?? null,
          payoutMethod: dto.payoutMethod,
          kycStatus: KycStatus.pending,
          contractVersion: dto.contractVersion,
          regulationsHash: dto.regulationsHash,
          signaturePath: `typed:${dto.signatureName}`,
          contractAcceptedAt: now,
        },
        update: {
          displayName: dto.displayName,
          legalName: dto.legalName,
          idNumber: dto.idNumber ?? null,
          payoutMethod: dto.payoutMethod,
          kycStatus: KycStatus.pending,
          contractVersion: dto.contractVersion,
          regulationsHash: dto.regulationsHash,
          signaturePath: `typed:${dto.signatureName}`,
          contractAcceptedAt: now,
        },
      });
      await tx.user.update({
        where: { id: userId },
        data: { role: UserRole.designer },
      });
      return profile;
    });
  }

  private slugify(value: string): string {
    const base = value
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, '-')
      .replace(/(^-|-$)/g, '');
    return base.length > 0 ? base : 'designer';
  }
}
