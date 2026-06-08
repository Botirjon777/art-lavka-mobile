import { Injectable } from '@nestjs/common';
import {
  LedgerEntryType,
  PayoutMethod,
  PayoutStatus,
  Prisma,
} from '@prisma/client';
import { AppException } from '../common/errors/app.exception';
import { ErrorCode } from '../common/errors/error-codes';
import { AppConstants } from '../config/constants';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class PayoutsService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Request a withdrawal (BACKEND_NODE.md §5). Validates balance ≥ minimum and
   * ≥ amount, then writes the payout + a matching ledger debit atomically.
   */
  async request(userId: string, amountNum: number) {
    const amount = BigInt(amountNum);
    if (amount < AppConstants.minPayoutUzs) {
      throw new AppException(
        ErrorCode.belowPayoutThreshold,
        'Amount is below the payout threshold',
        422,
      );
    }

    const agg = await this.prisma.ledgerEntry.aggregate({
      where: { designerId: userId },
      _sum: { amount: true },
    });
    const balance = agg._sum.amount ?? 0n;
    if (amount > balance) {
      throw new AppException(
        ErrorCode.validation,
        'Amount exceeds your available balance',
        422,
      );
    }

    const profile = await this.prisma.designerProfile.findUnique({
      where: { userId },
      select: { payoutMethod: true },
    });

    return this.prisma.$transaction(async (tx) => {
      const payout = await tx.payout.create({
        data: {
          designerId: userId,
          amount,
          status: PayoutStatus.requested,
          method: profile?.payoutMethod ?? PayoutMethod.card,
        },
      });
      // Matching debit ties the ledger to the payout (balance drops immediately).
      await tx.ledgerEntry.create({
        data: {
          designerId: userId,
          type: LedgerEntryType.payoutDebit,
          amount: -amount,
          payoutId: payout.id,
          memo: 'Payout requested',
        },
      });
      return payout;
    });
  }

  /** A page of the caller's payouts, newest first. */
  async myPayouts(userId: string, page = 0) {
    const pageSize = AppConstants.pageSize;
    const where: Prisma.PayoutWhereInput = { designerId: userId };
    const [data, total] = await Promise.all([
      this.prisma.payout.findMany({
        where,
        orderBy: { requestedAt: 'desc' },
        skip: page * pageSize,
        take: pageSize,
      }),
      this.prisma.payout.count({ where }),
    ]);
    return { data, page, pageSize, total };
  }
}
