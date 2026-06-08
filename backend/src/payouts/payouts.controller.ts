import {
  Body,
  Controller,
  DefaultValuePipe,
  Get,
  HttpCode,
  ParseIntPipe,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import type { AuthUser } from '../common/decorators/current-user.decorator';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RequestPayoutDto } from './dto/request-payout.dto';
import { PayoutsService } from './payouts.service';

/**
 * Designer withdrawals (BACKEND_NODE.md §5). JWT-scoped to `req.user.id`.
 * Role gating to designers tightens once onboarding (step 7) sets that role;
 * for now the balance check naturally bars non-earners.
 */
@Controller('payouts')
@UseGuards(JwtAuthGuard)
export class PayoutsController {
  constructor(private readonly payouts: PayoutsService) {}

  @Post('request')
  @HttpCode(200)
  request(@CurrentUser() user: AuthUser, @Body() dto: RequestPayoutDto) {
    return this.payouts.request(user.id, dto.amount);
  }

  @Get('me')
  myPayouts(
    @CurrentUser() user: AuthUser,
    @Query('page', new DefaultValuePipe(0), ParseIntPipe) page: number,
  ) {
    return this.payouts.myPayouts(user.id, page);
  }
}
