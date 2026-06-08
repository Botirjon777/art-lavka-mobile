import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { LedgerEntryType, OrderStatus, Prisma } from '@prisma/client';
import { AppConstants } from '../config/constants';
import { PrismaService } from '../prisma/prisma.service';

/**
 * The money ledger (BACKEND_NODE.md §5). Append-only: this service ONLY inserts
 * rows. A balance is `SUM(amount)`, never a stored field. Royalties accrue on
 * delivery + return-window, not at order creation.
 */
@Injectable()
export class LedgerService {
  private readonly logger = new Logger('Ledger');

  constructor(private readonly prisma: PrismaService) {}

  /** Current balance (UZS) for a designer = SUM of their ledger rows. */
  async balanceOf(designerId: string): Promise<bigint> {
    const agg = await this.prisma.ledgerEntry.aggregate({
      where: { designerId },
      _sum: { amount: true },
    });
    return agg._sum.amount ?? 0n;
  }

  /** A page of a designer's ledger entries, newest first. */
  async ledger(designerId: string, page = 0) {
    const pageSize = AppConstants.pageSize;
    const where: Prisma.LedgerEntryWhereInput = { designerId };
    const [data, total] = await Promise.all([
      this.prisma.ledgerEntry.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip: page * pageSize,
        take: pageSize,
      }),
      this.prisma.ledgerEntry.count({ where }),
    ]);
    return { data, page, pageSize, total };
  }

  /**
   * Accrue royalties for delivered items whose return window has passed and
   * that have not accrued yet. Idempotent via the "no royaltyAccrued row"
   * filter. Returns the number of rows written.
   */
  async accrueRoyalties(): Promise<number> {
    const cutoff = new Date(
      Date.now() - AppConstants.returnWindowDays * 86_400_000,
    );

    const items = await this.prisma.orderItem.findMany({
      where: {
        order: { status: OrderStatus.delivered, deliveredAt: { lte: cutoff } },
        ledger: { none: { type: LedgerEntryType.royaltyAccrued } },
      },
      select: { id: true, designerId: true, unitRoyalty: true, quantity: true },
    });
    if (items.length === 0) return 0;

    const rows: Prisma.LedgerEntryCreateManyInput[] = items.map((it) => ({
      designerId: it.designerId,
      type: LedgerEntryType.royaltyAccrued,
      amount: it.unitRoyalty * BigInt(it.quantity),
      orderItemId: it.id,
      memo: 'Royalty accrued after return window',
    }));
    const res = await this.prisma.ledgerEntry.createMany({ data: rows });
    this.logger.log(`Accrued royalties for ${res.count} items`);
    return res.count;
  }

  /**
   * Reverse accrued royalties for a refunded order (negative clawback rows).
   * Only reverses items that accrued and haven't been reversed yet.
   */
  async clawbackForOrder(orderId: string): Promise<number> {
    const accrued = await this.prisma.ledgerEntry.findMany({
      where: {
        type: LedgerEntryType.royaltyAccrued,
        orderItem: { orderId },
      },
      select: { designerId: true, amount: true, orderItemId: true },
    });
    if (accrued.length === 0) return 0;

    // Skip items already reversed.
    const reversedItemIds = new Set(
      (
        await this.prisma.ledgerEntry.findMany({
          where: {
            type: LedgerEntryType.refundReversal,
            orderItem: { orderId },
          },
          select: { orderItemId: true },
        })
      ).map((r) => r.orderItemId),
    );

    const rows: Prisma.LedgerEntryCreateManyInput[] = accrued
      .filter((a) => !reversedItemIds.has(a.orderItemId))
      .map((a) => ({
        designerId: a.designerId,
        type: LedgerEntryType.refundReversal,
        amount: -a.amount,
        orderItemId: a.orderItemId,
        memo: 'Royalty clawback on refund',
      }));
    if (rows.length === 0) return 0;

    const res = await this.prisma.ledgerEntry.createMany({ data: rows });
    this.logger.log(
      `Clawed back royalties for ${res.count} items (order ${orderId})`,
    );
    return res.count;
  }

  /** Daily scheduled accrual (BACKEND_NODE.md §5 "runs on a fixed schedule"). */
  @Cron(CronExpression.EVERY_DAY_AT_3AM)
  async scheduledAccrual(): Promise<void> {
    await this.accrueRoyalties();
  }
}
