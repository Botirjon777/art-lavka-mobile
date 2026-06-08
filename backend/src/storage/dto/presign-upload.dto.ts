import { IsIn, IsString } from 'class-validator';
import { UPLOAD_BUCKETS } from '../buckets';

export class PresignUploadDto {
  @IsIn(UPLOAD_BUCKETS)
  bucket!: string;

  @IsString()
  contentType!: string;
}
