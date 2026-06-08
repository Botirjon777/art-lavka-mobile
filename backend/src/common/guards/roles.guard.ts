import { CanActivate, ExecutionContext, Injectable } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { Request } from 'express';
import { AuthUser } from '../decorators/current-user.decorator';
import { AppException } from '../errors/app.exception';
import { ROLES_KEY } from '../decorators/roles.decorator';

/**
 * Role check (BACKEND_NODE.md §4). Pairs with `JwtAuthGuard` (which must run
 * first to populate `req.user`). Routes with no `@Roles` pass through.
 */
@Injectable()
export class RolesGuard implements CanActivate {
  constructor(private readonly reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    const required = this.reflector.getAllAndOverride<string[]>(ROLES_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);
    if (!required || required.length === 0) return true;

    const req = context
      .switchToHttp()
      .getRequest<Request & { user?: AuthUser }>();
    const role = req.user?.role;
    if (!role || !required.includes(role)) {
      throw AppException.forbidden('Insufficient role');
    }
    return true;
  }
}
