import { AppException } from './errors/app.exception';

/**
 * The RLS replacement at the service layer (BACKEND_NODE.md §4/§9).
 *
 * Call in EVERY service method that touches user-scoped data, comparing the
 * authenticated user's id (`req.user.id`, never a body/param id) to the
 * resource owner's id. A missing check leaks another user's data or money —
 * treat its absence on such a method as a bug.
 *
 * @throws AppException 403 when the ids differ.
 */
export function assertOwnership(
  currentUserId: string,
  ownerId: string | null | undefined,
  message = 'You do not have access to this resource',
): void {
  if (!ownerId || ownerId !== currentUserId) {
    throw AppException.forbidden(message);
  }
}
