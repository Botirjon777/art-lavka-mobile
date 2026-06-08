import { CanActivate, ExecutionContext, Injectable } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Request } from 'express';
import { AuthUser } from '../decorators/current-user.decorator';
import { AppException } from '../errors/app.exception';

interface AccessTokenPayload {
  sub: string;
  role: string;
}

/**
 * Layer 1 of the RLS replacement (BACKEND_NODE.md §4): no valid access token,
 * no entry. Verifies the Bearer JWT and attaches `{ id, role }` to `req.user`.
 * Apply with `@UseGuards(JwtAuthGuard)` on every protected route.
 */
@Injectable()
export class JwtAuthGuard implements CanActivate {
  constructor(private readonly jwt: JwtService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const req = context.switchToHttp().getRequest<Request>();
    const token = this.extractBearer(req.headers.authorization);
    if (!token) throw AppException.unauthorized('Missing access token');

    try {
      const payload = await this.jwt.verifyAsync<AccessTokenPayload>(token);
      const user: AuthUser = { id: payload.sub, role: payload.role };
      (req as Request & { user: AuthUser }).user = user;
      return true;
    } catch {
      throw AppException.unauthorized('Invalid or expired token');
    }
  }

  private extractBearer(header?: string): string | null {
    if (!header) return null;
    const [scheme, value] = header.split(' ');
    return scheme === 'Bearer' && value ? value : null;
  }
}
