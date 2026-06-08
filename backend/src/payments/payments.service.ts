import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { OrderStatus, PaymentProvider } from '@prisma/client';
import { AppException } from '../common/errors/app.exception';
import { ErrorCode } from '../common/errors/error-codes';
import { PrismaService } from '../prisma/prisma.service';

type WebhookBody = Record<string, unknown>;

@Injectable()
export class PaymentsService {
  private readonly logger = new Logger('Payments');
  private readonly sandbox: boolean;

  constructor(
    private readonly prisma: PrismaService,
    config: ConfigService,
  ) {
    this.sandbox =
      (config.get<string>('PAYMENTS_SANDBOX') ?? 'false') === 'true';
  }

  /**
   * Handle a provider callback (BACKEND_NODE.md §5). Verifies the signature,
   * then transitions the order — idempotently (the same callback twice is a
   * no-op because we only move orders out of `pending`).
   */
  async handleWebhook(
    provider: string,
    body: WebhookBody,
  ): Promise<{ ok: boolean }> {
    if (!this.isKnownProvider(provider)) {
      throw AppException.notFound('Unknown payment provider');
    }
    if (!this.verifySignature(provider, body)) {
      throw new AppException(
        ErrorCode.unauthorized,
        'Invalid payment signature',
        401,
      );
    }

    const orderId = this.read(body, 'orderId', 'order_id');
    const status = this.read(body, 'status');
    const providerRef = this.read(body, 'providerRef', 'provider_ref');
    if (!orderId) throw AppException.validation('Missing order id');

    if (status === 'paid') {
      const res = await this.prisma.order.updateMany({
        where: { id: orderId, status: OrderStatus.pending },
        data: {
          status: OrderStatus.paid,
          paidAt: new Date(),
          providerRef: providerRef ?? null,
        },
      });
      this.logger.log(`order ${orderId} paid (${res.count} updated)`);
    } else if (status === 'failed') {
      await this.prisma.order.updateMany({
        where: { id: orderId, status: OrderStatus.pending },
        data: { status: OrderStatus.cancelled },
      });
    }

    return { ok: true };
  }

  /**
   * Until provider credentials exist, only sandbox mode is trusted — this must
   * NEVER return true for an unverified production callback.
   */
  private verifySignature(provider: string, body: WebhookBody): boolean {
    if (this.sandbox) return true;
    // TODO: per-provider HMAC verification with CLICK_SECRET / PAYME_KEY /
    // UZUM_KEY before trusting any production callback.
    this.logger.warn(
      `Rejected unverified ${provider} webhook (${Object.keys(body).length} fields)`,
    );
    return false;
  }

  private isKnownProvider(provider: string): provider is PaymentProvider {
    return (Object.values(PaymentProvider) as string[]).includes(provider);
  }

  private read(body: WebhookBody, ...keys: string[]): string | undefined {
    for (const key of keys) {
      const value = body[key];
      if (typeof value === 'string' && value.length > 0) return value;
    }
    return undefined;
  }
}
