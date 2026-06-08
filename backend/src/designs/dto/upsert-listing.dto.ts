import { IsBoolean, IsInt, IsOptional, IsUUID, Min } from 'class-validator';

export class UpsertListingDto {
  @IsUUID()
  designId!: string;

  @IsUUID()
  productTypeId!: string;

  /** UZS royalty; bounds enforced server-side. */
  @IsInt()
  @Min(0)
  royalty!: number;

  @IsOptional()
  @IsBoolean()
  active?: boolean;
}
