import { Controller, Get, Param, Query } from '@nestjs/common';
import { CatalogService } from './catalog.service';
import { ListingsQueryDto } from './dto/listings-query.dto';
import { SearchQueryDto } from './dto/search-query.dto';

/** Public catalog read path (BACKEND_NODE.md §5). No auth. */
@Controller('catalog')
export class CatalogController {
  constructor(private readonly catalog: CatalogService) {}

  @Get('categories')
  categories() {
    return this.catalog.categories();
  }

  @Get('product-types')
  productTypes() {
    return this.catalog.productTypes();
  }

  @Get('banners')
  banners() {
    return this.catalog.banners();
  }

  @Get('listings')
  listings(@Query() query: ListingsQueryDto) {
    return this.catalog.listings(query);
  }

  @Get('search')
  search(@Query() query: SearchQueryDto) {
    return this.catalog.search(query.q, query.page);
  }

  @Get('listings/:id')
  listing(@Param('id') id: string) {
    return this.catalog.listing(id);
  }

  @Get('designs/:designId/reviews')
  reviews(@Param('designId') designId: string) {
    return this.catalog.reviewsForDesign(designId);
  }
}
