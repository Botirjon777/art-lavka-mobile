import {
  IsArray,
  IsInt,
  IsOptional,
  IsString,
  IsUUID,
  Min,
  MinLength,
} from 'class-validator';

export class CreateDesignDto {
  @IsString()
  @MinLength(1)
  title!: string;

  @IsOptional()
  @IsString()
  description?: string;

  /** Public watermarked preview path/URL (already uploaded via presign). */
  @IsString()
  previewUrl!: string;

  /** Private print-file path in the `print-files` bucket. */
  @IsString()
  printFilePath!: string;

  @IsInt()
  @Min(1)
  widthPx!: number;

  @IsInt()
  @Min(1)
  heightPx!: number;

  @IsOptional()
  @IsArray()
  @IsUUID('all', { each: true })
  categoryIds?: string[];
}
