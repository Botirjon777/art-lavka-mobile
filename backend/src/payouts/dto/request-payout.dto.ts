import { IsInt, Min } from 'class-validator';

export class RequestPayoutDto {
  /** UZS amount to withdraw (integer). */
  @IsInt()
  @Min(1)
  amount!: number;
}
