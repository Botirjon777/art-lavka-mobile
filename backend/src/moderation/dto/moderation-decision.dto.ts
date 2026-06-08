import { IsIn, IsOptional, IsString } from 'class-validator';

export class ModerationDecisionDto {
  @IsIn(['approve', 'reject'])
  decision!: 'approve' | 'reject';

  /** Required-in-spirit for rejections; surfaced to the designer. */
  @IsOptional()
  @IsString()
  reason?: string;
}
