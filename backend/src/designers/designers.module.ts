import { Module } from '@nestjs/common';
import { DesignersController } from './designers.controller';
import { DesignersService } from './designers.service';

@Module({
  controllers: [DesignersController],
  providers: [DesignersService],
})
export class DesignersModule {}
