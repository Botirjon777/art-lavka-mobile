import { createHash, randomBytes } from 'node:crypto';
import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { AppException } from '../common/errors/app.exception';
import { parseDurationMs } from '../common/duration';
import { PrismaService } from '../prisma/prisma.service';

export interface TokenPair {
  accessToken: string;
  refreshToken: string;
}

/**
 * Issues/rotates/revokes the JWT access token + opaque refresh token.
 *
 * - Access: short-lived JWT (access secret), payload `{ sub, role }`.
 * - Refresh: high-entropy random string; only its SHA-256 hash is stored
 *   (`refresh_tokens`), enabling revocation (logout) and rotation on use.
 */
@Injectable()
export class TokensService {
  constructor(
    private readonly jwt: JwtService,
    private readonly config: ConfigService,
    private readonly prisma: PrismaService,
  ) {}

  async issuePair(userId: string, role: string): Promise<TokenPair> {
    const accessTtlMs = parseDurationMs(
      this.config.get<string>('ACCESS_TOKEN_TTL'),
      15 * 60_000,
    );
    const accessToken = await this.jwt.signAsync(
      { sub: userId, role },
      {
        secret: this.config.get<string>('JWT_ACCESS_SECRET'),
        expiresIn: Math.floor(accessTtlMs / 1000), // seconds (number)
      },
    );

    const refreshToken = randomBytes(48).toString('hex');
    const refreshTtlMs = parseDurationMs(
      this.config.get<string>('REFRESH_TOKEN_TTL'),
      30 * 86_400_000,
    );
    await this.prisma.refreshToken.create({
      data: {
        userId,
        tokenHash: this.hash(refreshToken),
        expiresAt: new Date(Date.now() + refreshTtlMs),
      },
    });

    return { accessToken, refreshToken };
  }

  /** Validate a refresh token, revoke it, and issue a fresh pair (rotation). */
  async rotate(rawRefresh: string): Promise<TokenPair> {
    const row = await this.prisma.refreshToken.findUnique({
      where: { tokenHash: this.hash(rawRefresh) },
      include: { user: true },
    });
    if (!row || row.revokedAt || row.expiresAt < new Date()) {
      throw AppException.unauthorized('Invalid or expired refresh token');
    }
    await this.prisma.refreshToken.update({
      where: { id: row.id },
      data: { revokedAt: new Date() },
    });
    return this.issuePair(row.userId, row.user.role);
  }

  /** Revoke a refresh token (logout). Idempotent. */
  async revoke(rawRefresh: string): Promise<void> {
    await this.prisma.refreshToken.updateMany({
      where: { tokenHash: this.hash(rawRefresh), revokedAt: null },
      data: { revokedAt: new Date() },
    });
  }

  private hash(raw: string): string {
    return createHash('sha256').update(raw).digest('hex');
  }
}
