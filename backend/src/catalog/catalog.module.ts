import { Module } from '@nestjs/common';
import { CatalogController } from './catalog.controller';
import { CatalogService } from './catalog.service';
import { StorefrontsController } from './storefronts.controller';

@Module({
  controllers: [CatalogController, StorefrontsController],
  providers: [CatalogService],
})
export class CatalogModule {}
