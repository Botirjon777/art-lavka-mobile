import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

/**
 * Delivers OTP codes. Channels, in priority order:
 *  1. **Telegram** — if `TELEGRAM_BOT_TOKEN` + `TELEGRAM_CHAT_ID` are set, posts
 *     the code to a Telegram chat/group (great for team testing).
 *  2. **Mock** — if `MOCK_SMS=true`, logs the code (visible in server logs).
 *  3. Otherwise throws (no real SMS provider wired yet).
 *
 * A real +998 SMS provider (Eskiz / Play Mobile) slots in as another channel.
 */
@Injectable()
export class SmsService {
  private readonly logger = new Logger('Otp');
  private readonly mock: boolean;
  private readonly telegramToken?: string;
  private readonly telegramChatId?: string;

  constructor(config: ConfigService) {
    this.mock = (config.get<string>('MOCK_SMS') ?? 'true') === 'true';
    this.telegramToken = this.clean(config.get<string>('TELEGRAM_BOT_TOKEN'));
    this.telegramChatId = this.clean(config.get<string>('TELEGRAM_CHAT_ID'));
  }

  async sendOtp(phone: string, code: string): Promise<void> {
    const text = `🔐 ART-LAVKA\nPhone: ${phone}\nCode: ${code}`;

    if (this.telegramToken && this.telegramChatId) {
      try {
        await this.sendTelegram(text);
        return;
      } catch (error) {
        // Log token LENGTH (not the secret) so a malformed env value is obvious.
        this.logger.error(
          `Telegram send failed (tokenLen=${this.telegramToken.length}, ` +
            `chatId=${this.telegramChatId}): ${String(error)}`,
        );
        // fall through to the mock log so testing isn't blocked
      }
    }

    if (this.mock) {
      this.logger.warn(`[MOCK OTP] ${phone} -> ${code}`);
      return;
    }

    throw new Error('No OTP delivery channel configured');
  }

  private async sendTelegram(text: string): Promise<void> {
    const url = `https://api.telegram.org/bot${this.telegramToken}/sendMessage`;
    const res = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ chat_id: this.telegramChatId, text }),
    });
    if (!res.ok) {
      throw new Error(`Telegram API ${res.status}`);
    }
  }

  /** Strip surrounding quotes/whitespace that often sneak into env values. */
  private clean(value?: string): string | undefined {
    if (value == null) return undefined;
    const trimmed = value
      .trim()
      .replace(/^["']|["']$/g, '')
      .trim();
    return trimmed.length > 0 ? trimmed : undefined;
  }
}
