import { Module } from '@nestjs/common';
import { ThrottlerModule } from '@nestjs/throttler';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { SmsService } from './sms.service';
import { TokensService } from './tokens.service';

@Module({
  imports: [
    // Default per-IP limit; OTP routes tighten this via @Throttle.
    ThrottlerModule.forRoot([{ ttl: 60_000, limit: 30 }]),
  ],
  controllers: [AuthController],
  providers: [AuthService, TokensService, SmsService],
})
export class AuthModule {}
