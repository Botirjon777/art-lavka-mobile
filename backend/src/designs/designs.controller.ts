import {
  Body,
  Controller,
  DefaultValuePipe,
  Get,
  Param,
  ParseIntPipe,
  ParseUUIDPipe,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import type { AuthUser } from '../common/decorators/current-user.decorator';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { DesignsService } from './designs.service';
import { CreateDesignDto } from './dto/create-design.dto';
import { UpdateListingDto } from './dto/update-listing.dto';
import { UpsertListingDto } from './dto/upsert-listing.dto';

/**
 * A designer's own designs + listings (BACKEND_NODE.md §5). Ownership enforced
 * per method via `req.user.id`. (Designer-role gating tightens after onboarding.)
 */
@Controller('designs')
@UseGuards(JwtAuthGuard)
export class DesignsController {
  constructor(private readonly designs: DesignsService) {}

  @Post()
  create(@CurrentUser() user: AuthUser, @Body() dto: CreateDesignDto) {
    return this.designs.createDesign(user.id, dto);
  }

  @Get('me')
  myDesigns(
    @CurrentUser() user: AuthUser,
    @Query('page', new DefaultValuePipe(0), ParseIntPipe) page: number,
  ) {
    return this.designs.myDesigns(user.id, page);
  }

  @Post('listings')
  upsertListing(@CurrentUser() user: AuthUser, @Body() dto: UpsertListingDto) {
    return this.designs.upsertListing(user.id, dto);
  }

  @Patch('listings/:id')
  updateListing(
    @CurrentUser() user: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateListingDto,
  ) {
    return this.designs.updateListing(user.id, id, dto);
  }
}
