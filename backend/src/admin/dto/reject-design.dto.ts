import { IsOptional, IsString, MaxLength } from 'class-validator';

export class RejectDesignDto {
  /** Shown to the seller on the rejected design. */
  @IsOptional()
  @IsString()
  @MaxLength(500)
  reason?: string;
}
