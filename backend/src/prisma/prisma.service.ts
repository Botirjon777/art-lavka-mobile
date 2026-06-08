import { Injectable, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';

/**
 * Singleton Prisma client. Inject this everywhere instead of `new PrismaClient`.
 *
 * Ledger integrity note (BACKEND_NODE.md §3): the ledger is append-only — only
 * ever `.create()` rows on it, never update/delete. A DB-role safeguard
 * (revoke UPDATE/DELETE on `ledger`) backs this at the database level.
 */
@Injectable()
export class PrismaService
  extends PrismaClient
  implements OnModuleInit, OnModuleDestroy
{
  async onModuleInit(): Promise<void> {
    await this.$connect();
  }

  async onModuleDestroy(): Promise<void> {
    await this.$disconnect();
  }
}
