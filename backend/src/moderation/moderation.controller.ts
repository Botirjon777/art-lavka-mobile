import {
  Body,
  Controller,
  DefaultValuePipe,
  Get,
  Param,
  ParseIntPipe,
  ParseUUIDPipe,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { Roles } from '../common/decorators/roles.decorator';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { ModerationDecisionDto } from './dto/moderation-decision.dto';
import { ModerationService } from './moderation.service';

@Controller('moderation')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('moderator', 'admin')
export class ModerationController {
  constructor(private readonly moderation: ModerationService) {}

  @Get('queue')
  queue(@Query('page', new DefaultValuePipe(0), ParseIntPipe) page: number) {
    return this.moderation.queue(page);
  }

  @Post(':designId/decision')
  decide(
    @Param('designId', ParseUUIDPipe) designId: string,
    @Body() dto: ModerationDecisionDto,
  ) {
    return this.moderation.decide(designId, dto);
  }
}
