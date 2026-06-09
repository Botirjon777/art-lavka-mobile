import {
  Body,
  Controller,
  DefaultValuePipe,
  Get,
  Param,
  ParseEnumPipe,
  ParseIntPipe,
  ParseUUIDPipe,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { DesignStatus, KycStatus } from '@prisma/client';
import { Roles } from '../common/decorators/roles.decorator';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { UpdateListingDto } from '../designs/dto/update-listing.dto';
import { AdminService } from './admin.service';
import { RejectDesignDto } from './dto/reject-design.dto';

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

  // ---- Shops -------------------------------------------------------------

  @Get('shops')
  shops(
    @Query('status', new ParseEnumPipe(KycStatus, { optional: true }))
    status: KycStatus | undefined,
    @Query('page', new DefaultValuePipe(0), ParseIntPipe) page: number,
  ) {
    return this.admin.shops(status, page);
  }

  @Get('shops/:userId')
  shopDetail(@Param('userId', ParseUUIDPipe) userId: string) {
    return this.admin.shopDetail(userId);
  }

  // ---- Design moderation -------------------------------------------------

  @Get('designs')
  designs(
    @Query('status', new ParseEnumPipe(DesignStatus, { optional: true }))
    status: DesignStatus | undefined,
    @Query('page', new DefaultValuePipe(0), ParseIntPipe) page: number,
  ) {
    return this.admin.designs(status, page);
  }

  @Get('designs/:id')
  designDetail(@Param('id', ParseUUIDPipe) id: string) {
    return this.admin.designDetail(id);
  }

  @Post('designs/:id/approve')
  approveDesign(@Param('id', ParseUUIDPipe) id: string) {
    return this.admin.approveDesign(id);
  }

  @Post('designs/:id/reject')
  rejectDesign(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: RejectDesignDto,
  ) {
    return this.admin.rejectDesign(id, dto.reason);
  }

  @Patch('listings/:id')
  setListing(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateListingDto,
  ) {
    return this.admin.setListing(id, dto);
  }
}
