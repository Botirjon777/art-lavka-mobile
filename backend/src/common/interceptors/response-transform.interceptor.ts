import {
  CallHandler,
  ExecutionContext,
  Injectable,
  NestInterceptor,
} from '@nestjs/common';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { deepSnakeCase } from '../case';

/**
 * Serializes every successful response body with snake_case keys so the Flutter
 * models' `fromJson` parse it unchanged after the REST swap (BACKEND_NODE.md §7).
 * Error responses bypass interceptors, so the `{ error: { code, message } }`
 * shape is unaffected.
 */
@Injectable()
export class ResponseTransformInterceptor implements NestInterceptor {
  intercept(
    _context: ExecutionContext,
    next: CallHandler,
  ): Observable<unknown> {
    return next.handle().pipe(map((data) => deepSnakeCase(data)));
  }
}
