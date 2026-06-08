import { randomInt } from 'node:crypto';
import { Injectable } from '@nestjs/common';
import * as bcrypt from 'bcryptjs';
import { AppException } from '../common/errors/app.exception';
import { ErrorCode } from '../common/errors/error-codes';
import { isValidUzPhone, normalizePhone } from '../common/phone';
import { AppConstants } from '../config/constants';
import { PrismaService } from '../prisma/prisma.service';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { SmsService } from './sms.service';
import { TokenPair, TokensService } from './tokens.service';

/** Scalar user fields safe to return to the client (no KYC, no relations). */
const USER_SELECT = {
  id: true,
  phone: true,
  email: true,
  fullName: true,
  avatarUrl: true,
  languageCode: true,
  role: true,
  createdAt: true,
} as const;

type PublicUser = {
  id: string;
  phone: string;
  email: string | null;
  fullName: string | null;
  avatarUrl: string | null;
  languageCode: string;
  role: string;
  createdAt: Date;
};

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly sms: SmsService,
    private readonly tokens: TokensService,
  ) {}

  /**
   * Generate + store a hashed OTP and send it. Per-phone cooldown enforced;
   * the response never reveals whether the phone exists (BACKEND_NODE.md §4).
   */
  async requestOtp(rawPhone: string): Promise<void> {
    if (!isValidUzPhone(rawPhone)) {
      throw new AppException(ErrorCode.invalidPhone, 'Invalid phone', 422);
    }
    const phone = normalizePhone(rawPhone);

    const recent = await this.prisma.otpCode.findFirst({
      where: { phone },
      orderBy: { createdAt: 'desc' },
    });
    if (
      recent &&
      Date.now() - recent.createdAt.getTime() <
        AppConstants.otpResendSeconds * 1000
    ) {
      throw new AppException(
        ErrorCode.otpThrottled,
        'Please wait before requesting another code',
        429,
      );
    }

    const code = this.generateCode();
    await this.prisma.otpCode.create({
      data: {
        phone,
        codeHash: await bcrypt.hash(code, 10),
        expiresAt: new Date(Date.now() + AppConstants.otpTtlSeconds * 1000),
      },
    });
    await this.sms.sendOtp(phone, code);
  }

  /** Verify the code; on success find/create the user and issue tokens. */
  async verifyOtp(
    rawPhone: string,
    code: string,
  ): Promise<{ user: PublicUser; tokens: TokenPair }> {
    const phone = normalizePhone(rawPhone);
    const otp = await this.prisma.otpCode.findFirst({
      where: { phone, consumed: false },
      orderBy: { createdAt: 'desc' },
    });
    if (!otp) {
      throw new AppException(ErrorCode.otpWrong, 'No code requested', 422);
    }
    if (otp.expiresAt < new Date()) {
      throw new AppException(ErrorCode.otpExpired, 'Code expired', 422);
    }
    if (otp.attempts >= AppConstants.otpMaxAttempts) {
      throw new AppException(ErrorCode.otpThrottled, 'Too many attempts', 429);
    }

    const matches = await bcrypt.compare(code, otp.codeHash);
    if (!matches) {
      await this.prisma.otpCode.update({
        where: { id: otp.id },
        data: { attempts: { increment: 1 } },
      });
      throw new AppException(ErrorCode.otpWrong, 'That code is not right', 422);
    }

    await this.prisma.otpCode.update({
      where: { id: otp.id },
      data: { consumed: true },
    });

    const user = await this.prisma.user.upsert({
      where: { phone },
      update: {},
      create: { phone },
      select: USER_SELECT,
    });
    const tokens = await this.tokens.issuePair(user.id, user.role);
    return { user, tokens };
  }

  async me(userId: string): Promise<PublicUser> {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: USER_SELECT,
    });
    if (!user) throw AppException.notFound('User not found');
    return user;
  }

  async updateProfile(
    userId: string,
    dto: UpdateProfileDto,
  ): Promise<PublicUser> {
    return this.prisma.user.update({
      where: { id: userId },
      data: {
        fullName: dto.fullName,
        languageCode: dto.languageCode,
        ...(dto.email !== undefined ? { email: dto.email } : {}),
        ...(dto.avatarUrl !== undefined ? { avatarUrl: dto.avatarUrl } : {}),
      },
      select: USER_SELECT,
    });
  }

  refresh(rawRefresh: string): Promise<TokenPair> {
    return this.tokens.rotate(rawRefresh);
  }

  logout(rawRefresh: string): Promise<void> {
    return this.tokens.revoke(rawRefresh);
  }

  private generateCode(): string {
    const max = 10 ** AppConstants.otpLength;
    return randomInt(0, max).toString().padStart(AppConstants.otpLength, '0');
  }
}
