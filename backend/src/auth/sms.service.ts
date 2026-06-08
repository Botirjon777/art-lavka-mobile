import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

/**
 * Sends OTP SMS. In development (`MOCK_SMS=true`) it logs the code instead of
 * sending, so auth is fully testable before a live +998 provider (Eskiz.uz /
 * Play Mobile) is wired (BACKEND_NODE.md §1/§8).
 */
@Injectable()
export class SmsService {
  private readonly logger = new Logger('Sms');
  private readonly mock: boolean;

  constructor(config: ConfigService) {
    this.mock = (config.get<string>('MOCK_SMS') ?? 'true') === 'true';
  }

  async sendOtp(phone: string, code: string): Promise<void> {
    const message = `ART-LAVKA: kod / код / code: ${code}`;
    if (this.mock) {
      this.logger.warn(`[MOCK SMS] ${phone} -> ${message}`);
      return;
    }
    // TODO: integrate Eskiz.uz / Play Mobile using ESKIZ_* env credentials.
    await Promise.resolve();
    throw new Error(
      'No live SMS provider configured (set MOCK_SMS=true for dev)',
    );
  }
}
