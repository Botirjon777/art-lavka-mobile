import {
  Body,
  Controller,
  DefaultValuePipe,
  Get,
  Param,
  ParseIntPipe,
  ParseUUIDPipe,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import type { AuthUser } from '../common/decorators/current-user.decorator';
import { Roles } from '../common/decorators/roles.decorator';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { CreateOrderDto } from './dto/create-order.dto';
import { UpdateOrderStatusDto } from './dto/update-order-status.dto';
import { OrdersService } from './orders.service';

@Controller('orders')
@UseGuards(JwtAuthGuard)
export class OrdersController {
  constructor(private readonly orders: OrdersService) {}

  /** Create an order (price recomputed server-side) → payment intent. */
  @Post()
  async create(@CurrentUser() user: AuthUser, @Body() dto: CreateOrderDto) {
    const { intent } = await this.orders.createOrder(user.id, dto);
    return intent;
  }

  /** The caller's orders (ownership scoped). */
  @Get('me')
  myOrders(
    @CurrentUser() user: AuthUser,
    @Query('page', new DefaultValuePipe(0), ParseIntPipe) page: number,
  ) {
    return this.orders.myOrders(user.id, page);
  }

  /** One of the caller's orders. */
  @Get(':id')
  order(@CurrentUser() user: AuthUser, @Param('id', ParseUUIDPipe) id: string) {
    return this.orders.order(user.id, id);
  }

  /** Ops/admin: advance order status (production → shipped → delivered, …). */
  @Patch(':id/status')
  @UseGuards(RolesGuard)
  @Roles('operations', 'admin')
  updateStatus(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateOrderStatusDto,
  ) {
    return this.orders.updateStatus(id, dto.status);
  }
}
