import {
  Controller,
  DefaultValuePipe,
  Get,
  ParseIntPipe,
  Query,
  UseGuards,
} from '@nestjs/common';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import type { AuthUser } from '../common/decorators/current-user.decorator';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { LedgerService } from './ledger.service';

/** A designer's own earnings (BACKEND_NODE.md §5). Scoped to `req.user.id`. */
@Controller('designers/me')
@UseGuards(JwtAuthGuard)
export class EarningsController {
  constructor(private readonly ledger: LedgerService) {}

  @Get('balance')
  async balance(@CurrentUser() user: AuthUser): Promise<{ balance: bigint }> {
    return { balance: await this.ledger.balanceOf(user.id) };
  }

  @Get('ledger')
  ledgerEntries(
    @CurrentUser() user: AuthUser,
    @Query('page', new DefaultValuePipe(0), ParseIntPipe) page: number,
  ) {
    return this.ledger.ledger(user.id, page);
  }
}
