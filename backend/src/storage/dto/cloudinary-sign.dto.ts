import { IsIn, IsOptional } from 'class-validator';
import { CLOUDINARY_FOLDERS } from '../storage.service';

export class CloudinarySignDto {
  /** Target folder; defaults to the prints folder. */
  @IsOptional()
  @IsIn(CLOUDINARY_FOLDERS)
  folder?: string;
}
