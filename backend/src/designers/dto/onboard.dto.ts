import { PayoutMethod } from '@prisma/client';
import { IsEnum, IsOptional, IsString, MinLength } from 'class-validator';

/// Seller onboarding payload (SPEC §9): KYC + accepted contract + signature.
export class OnboardDto {
  @IsString()
  @MinLength(1)
  displayName!: string;

  @IsString()
  @MinLength(1)
  legalName!: string;

  @IsOptional()
  @IsString()
  idNumber?: string;

  @IsEnum(PayoutMethod)
  payoutMethod!: PayoutMethod;

  /// Version of the regulations the seller accepted.
  @IsString()
  contractVersion!: string;

  /// Hash of the exact regulations text shown (enforceability — SPEC §9).
  @IsString()
  regulationsHash!: string;

  /// Typed e-signature (full name). A drawn signature would be uploaded to the
  /// private `signatures` bucket and referenced instead.
  @IsString()
  @MinLength(1)
  signatureName!: string;
}
