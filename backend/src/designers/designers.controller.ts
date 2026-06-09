import { Body, Controller, Get, Post, UseGuards } from '@nestjs/common';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import type { AuthUser } from '../common/decorators/current-user.decorator';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { DesignersService } from './designers.service';
import { OnboardDto } from './dto/onboard.dto';

/// Seller onboarding + profile (SPEC §9). Scoped to the authenticated user.
@Controller('designers')
@UseGuards(JwtAuthGuard)
export class DesignersController {
  constructor(private readonly designers: DesignersService) {}

  @Get('me/profile')
  meProfile(@CurrentUser() user: AuthUser) {
    return this.designers.meProfile(user.id);
  }

  @Get('me/stats')
  meStats(@CurrentUser() user: AuthUser) {
    return this.designers.meStats(user.id);
  }

  @Post('onboard')
  onboard(@CurrentUser() user: AuthUser, @Body() dto: OnboardDto) {
    return this.designers.onboard(user.id, dto);
  }
}
