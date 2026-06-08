import { HttpException, HttpStatus } from '@nestjs/common';
import { ErrorCode } from './error-codes';

/**
 * The one exception type services throw. Carries a stable [ErrorCode] plus an
 * HTTP status; the global filter renders it as `{ error: { code, message } }`.
 *
 * Throw these instead of raw Nest exceptions so every failure has a code the
 * Flutter side can localize. Convenience factories cover the common cases.
 */
export class AppException extends HttpException {
  constructor(
    readonly code: string,
    message: string,
    status: HttpStatus = HttpStatus.BAD_REQUEST,
  ) {
    super({ error: { code, message } }, status);
  }

  static unauthorized(message = 'Unauthorized'): AppException {
    return new AppException(
      ErrorCode.unauthorized,
      message,
      HttpStatus.UNAUTHORIZED,
    );
  }

  static forbidden(message = 'Forbidden'): AppException {
    return new AppException(
      ErrorCode.unauthorized,
      message,
      HttpStatus.FORBIDDEN,
    );
  }

  static notFound(message = 'Not found'): AppException {
    return new AppException(ErrorCode.notFound, message, HttpStatus.NOT_FOUND);
  }

  static validation(message = 'Validation failed'): AppException {
    return new AppException(
      ErrorCode.validation,
      message,
      HttpStatus.UNPROCESSABLE_ENTITY,
    );
  }
}
