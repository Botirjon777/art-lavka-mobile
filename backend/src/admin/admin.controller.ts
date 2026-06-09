import {
  Controller,
  DefaultValuePipe,
  Get,
  Param,
  ParseEnumPipe,
  ParseIntPipe,
  ParseUUIDPipe,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { KycStatus } from '@prisma/client';
import { Roles } from '../common/decorators/roles.decorator';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { AdminService } from './admin.service';

/** Web admin panel API (BACKEND_NODE.md §4 staff policies). Admin/moderator only. */
@Controller('admin')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('admin', 'moderator')
export class AdminController {
  constructor(private readonly admin: AdminService) {}

  @Get('stats')
  stats() {
    return this.admin.stats();
  }

  @Get('designers')
  designers(
    @Query('status', new ParseEnumPipe(KycStatus, { optional: true }))
    status: KycStatus | undefined,
    @Query('page', new DefaultValuePipe(0), ParseIntPipe) page: number,
  ) {
    return this.admin.designers(status, page);
  }

  @Get('designers/:userId')
  designerDetail(@Param('userId', ParseUUIDPipe) userId: string) {
    return this.admin.designerDetail(userId);
  }

  @Post('designers/:userId/verify')
  verify(@Param('userId', ParseUUIDPipe) userId: string) {
    return this.admin.verify(userId);
  }

  @Post('designers/:userId/reject')
  reject(@Param('userId', ParseUUIDPipe) userId: string) {
    return this.admin.reject(userId);
  }

  @Get('customers')
  customers(
    @Query('page', new DefaultValuePipe(0), ParseIntPipe) page: number,
  ) {
    return this.admin.customers(page);
  }
}
