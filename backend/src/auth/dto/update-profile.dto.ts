import {
  IsEmail,
  IsIn,
  IsOptional,
  IsString,
  MinLength,
} from 'class-validator';
import { AppConstants } from '../../config/constants';

export class UpdateProfileDto {
  @IsString()
  @MinLength(1)
  fullName!: string;

  @IsIn(AppConstants.supportedLanguageCodes)
  languageCode!: string;

  @IsOptional()
  @IsEmail()
  email?: string;

  @IsOptional()
  @IsString()
  avatarUrl?: string;
}
