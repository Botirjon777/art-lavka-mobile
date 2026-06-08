import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { JwtModule } from '@nestjs/jwt';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { AuthModule } from './auth/auth.module';
import { CatalogModule } from './catalog/catalog.module';
import { DesignersModule } from './designers/designers.module';
import { DesignsModule } from './designs/designs.module';
import { LedgerModule } from './ledger/ledger.module';
import { ModerationModule } from './moderation/moderation.module';
import { OrdersModule } from './orders/orders.module';
import { PaymentsModule } from './payments/payments.module';
import { PayoutsModule } from './payouts/payouts.module';
import { ReviewsModule } from './reviews/reviews.module';
import { StorageModule } from './storage/storage.module';
import { validateEnv } from './config/env.validation';
import { PrismaModule } from './prisma/prisma.module';

@Module({
  imports: [
    // Validated, global env config.
    ConfigModule.forRoot({ isGlobal: true, validate: validateEnv }),

    // Global Prisma access.
    PrismaModule,

    // Global JWT: the guard verifies access tokens with the access secret.
    // Signing (with explicit expiry/secret per token kind) happens in the auth
    // module, so no signOptions here.
    JwtModule.registerAsync({
      global: true,
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        secret: config.get<string>('JWT_ACCESS_SECRET'),
      }),
    }),

    // Feature modules (§8 migration plan):
    AuthModule,
    CatalogModule,
    OrdersModule,
    PaymentsModule,
    LedgerModule,
    PayoutsModule,
    DesignsModule,
    DesignersModule,
    ModerationModule,
    StorageModule,
    ReviewsModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
