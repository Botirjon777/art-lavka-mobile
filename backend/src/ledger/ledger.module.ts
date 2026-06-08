import { Module } from '@nestjs/common';
import { ScheduleModule } from '@nestjs/schedule';
import { EarningsController } from './earnings.controller';
import { LedgerController } from './ledger.controller';
import { LedgerService } from './ledger.service';

@Module({
  imports: [ScheduleModule.forRoot()],
  controllers: [EarningsController, LedgerController],
  providers: [LedgerService],
  exports: [LedgerService],
})
export class LedgerModule {}
