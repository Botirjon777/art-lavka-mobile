import { SetMetadata } from '@nestjs/common';

export const ROLES_KEY = 'roles';

/** `@Roles('moderator', 'admin')` — required roles, enforced by `RolesGuard`. */
export const Roles = (...roles: string[]) => SetMetadata(ROLES_KEY, roles);
