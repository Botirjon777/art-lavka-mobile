import { Body, Controller, HttpCode, Param, Post } from '@nestjs/common';
import { PaymentsService } from './payments.service';

/**
 * Payment provider callbacks (BACKEND_NODE.md §5). Public, but every call is
 * signature-verified inside the service. Body is provider-shaped, so it is not
 * validated by a DTO (the signature is the trust boundary).
 */
@Controller('payments')
export class PaymentsController {
  constructor(private readonly payments: PaymentsService) {}

  @Post('webhook/:provider')
  @HttpCode(200)
  webhook(
    @Param('provider') provider: string,
    @Body() body: Record<string, unknown>,
  ) {
    return this.payments.handleWebhook(provider, body);
  }
}
