import { PaymentProvider } from '@prisma/client';
import { Type } from 'class-transformer';
import {
  ArrayMinSize,
  IsArray,
  IsEnum,
  IsInt,
  IsOptional,
  IsString,
  IsUUID,
  Min,
  ValidateNested,
} from 'class-validator';

export class CreateOrderItemDto {
  @IsUUID()
  listingId!: string;

  @IsInt()
  @Min(1)
  quantity!: number;

  @IsOptional()
  @IsString()
  size?: string;

  @IsOptional()
  @IsString()
  color?: string;
}

export class CreateOrderDto {
  @IsArray()
  @ArrayMinSize(1)
  @ValidateNested({ each: true })
  @Type(() => CreateOrderItemDto)
  items!: CreateOrderItemDto[];

  @IsEnum(PaymentProvider)
  paymentProvider!: PaymentProvider;

  /** A saved address id (verified to belong to the caller) … */
  @IsOptional()
  @IsUUID()
  addressId?: string;

  /** … or a free-text address. One of the two should be present. */
  @IsOptional()
  @IsString()
  shippingAddress?: string;
}
