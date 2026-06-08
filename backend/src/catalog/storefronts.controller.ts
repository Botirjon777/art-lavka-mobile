import { Controller, Get, Param } from '@nestjs/common';
import { CatalogService } from './catalog.service';

/** Public designer storefronts (BACKEND_NODE.md §5). */
@Controller('storefronts')
export class StorefrontsController {
  constructor(private readonly catalog: CatalogService) {}

  @Get(':slug')
  storefront(@Param('slug') slug: string) {
    return this.catalog.storefront(slug);
  }
}
