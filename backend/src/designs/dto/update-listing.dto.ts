import { IsBoolean, IsInt, IsOptional, Min } from 'class-validator';

export class UpdateListingDto {
  @IsOptional()
  @IsInt()
  @Min(0)
  royalty?: number;

  @IsOptional()
  @IsBoolean()
  active?: boolean;
}
