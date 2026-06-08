import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpException,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import { Request, Response } from 'express';
import { ErrorCode } from '../errors/error-codes';

/**
 * Global exception filter → consistent `{ error: { code, message } }` shape
 * (BACKEND_NODE.md §6) so the Flutter `ErrorMapper` works unchanged.
 *
 * - `AppException` payloads already carry `{ error: { code, message } }`.
 * - Nest `ValidationPipe` errors map to `validation`.
 * - 401/403 map to `unauthorized`, 404 to `not_found`; everything else `server`.
 */
@Catch()
export class AllExceptionsFilter implements ExceptionFilter {
  private readonly logger = new Logger('Exceptions');

  catch(exception: unknown, host: ArgumentsHost): void {
    const ctx = host.switchToHttp();
    const res = ctx.getResponse<Response>();
    const req = ctx.getRequest<Request>();

    let status: number = HttpStatus.INTERNAL_SERVER_ERROR;
    let code: string = ErrorCode.server;
    let message = 'Something went wrong';

    if (exception instanceof HttpException) {
      status = exception.getStatus();
      const body = exception.getResponse();
      if (this.hasErrorShape(body)) {
        code = body.error.code;
        message = body.error.message;
      } else {
        ({ code, message } = this.fromStatus(status, body));
      }
    } else if (exception instanceof Error) {
      message = exception.message;
    }

    if (status >= 500) {
      this.logger.error(
        `${req.method} ${req.url} -> ${status}`,
        exception instanceof Error ? exception.stack : String(exception),
      );
    }

    res.status(status).json({ error: { code, message } });
  }

  private hasErrorShape(
    body: unknown,
  ): body is { error: { code: string; message: string } } {
    return (
      typeof body === 'object' &&
      body !== null &&
      'error' in body &&
      typeof (body as { error?: unknown }).error === 'object'
    );
  }

  private fromStatus(
    status: number,
    body: unknown,
  ): { code: string; message: string } {
    // Pull a message out of Nest's default `{ message, error, statusCode }`.
    let message = 'Request failed';
    if (typeof body === 'object' && body !== null && 'message' in body) {
      const m = body.message;
      message = Array.isArray(m) ? m.join('; ') : String(m);
    } else if (typeof body === 'string') {
      message = body;
    }

    // Numeric HTTP codes (not the HttpStatus enum) so we compare number-to-number.
    switch (status) {
      case 401: // Unauthorized
      case 403: // Forbidden
        return { code: ErrorCode.unauthorized, message };
      case 404: // Not Found
        return { code: ErrorCode.notFound, message };
      case 400: // Bad Request
      case 422: // Unprocessable Entity
        return { code: ErrorCode.validation, message };
      default:
        return { code: ErrorCode.server, message };
    }
  }
}
