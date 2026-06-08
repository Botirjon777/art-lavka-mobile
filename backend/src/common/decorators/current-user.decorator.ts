import { createParamDecorator, ExecutionContext } from '@nestjs/common';

/** Shape attached to `req.user` by `JwtAuthGuard`. */
export interface AuthUser {
  id: string;
  role: string;
}

/**
 * `@CurrentUser()` → the authenticated user from the JWT. NEVER trust an id from
 * the request body/params for "my data" endpoints — use this (BACKEND_NODE.md §4).
 */
export const CurrentUser = createParamDecorator(
  (_data: unknown, ctx: ExecutionContext): AuthUser => {
    const req = ctx.switchToHttp().getRequest<{ user?: AuthUser }>();
    if (!req.user) {
      // Should never happen on a JwtAuthGuard-protected route.
      throw new Error('CurrentUser used on a route without JwtAuthGuard');
    }
    return req.user;
  },
);
