import { Controller, HttpCode, Post, UseGuards } from '@nestjs/common';
import { Roles } from '../common/decorators/roles.decorator';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { LedgerService } from './ledger.service';

/** Ops-only ledger operations. Accrual also runs on a daily cron. */
@Controller('ledger')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('operations', 'admin')
export class LedgerController {
  constructor(private readonly ledger: LedgerService) {}

  /** Manually trigger royalty accrual (idempotent). */
  @Post('accrue-royalties')
  @HttpCode(200)
  async accrue(): Promise<{ accrued: number }> {
    return { accrued: await this.ledger.accrueRoyalties() };
  }
}
