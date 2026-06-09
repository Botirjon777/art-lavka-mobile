import { Body, Controller, Get, Param, Post, UseGuards } from '@nestjs/common';
import { Roles } from '../common/decorators/roles.decorator';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { CloudinarySignDto } from './dto/cloudinary-sign.dto';
import { PresignUploadDto } from './dto/presign-upload.dto';
import { StorageService } from './storage.service';

@Controller('storage')
@UseGuards(JwtAuthGuard)
export class StorageController {
  constructor(private readonly storage: StorageService) {}

  /** Presigned PUT for an upload bucket (designer uploads print files/previews). */
  @Post('presign-upload')
  presignUpload(@Body() dto: PresignUploadDto) {
    return this.storage.presignUpload(dto.bucket, dto.contentType);
  }

  /** Signed params for a direct Cloudinary upload (designer print artwork). */
  @Post('cloudinary-sign')
  cloudinarySign(@Body() dto: CloudinarySignDto) {
    return this.storage.cloudinarySign(dto.folder ?? 'art-lavka/prints');
  }

  /** Short-lived signed GET for a private print file — ops/admin ONLY (§13). */
  @Get('print-file/:designId')
  @UseGuards(RolesGuard)
  @Roles('operations', 'admin')
  printFile(@Param('designId') designId: string) {
    return this.storage.presignPrintFile(designId);
  }
}
