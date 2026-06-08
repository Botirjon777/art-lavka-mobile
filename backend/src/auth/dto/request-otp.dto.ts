import { IsString, MinLength } from 'class-validator';

export class RequestOtpDto {
  @IsString()
  @MinLength(6)
  phone!: string;
}
