import { Controller, Get } from '@nestjs/common';
import { AppService } from './app.service';

@Controller()
export class AppController {
  constructor(private readonly appService: AppService) {}

  /** Liveness probe. Public. */
  @Get('health')
  health(): { status: string; service: string } {
    return this.appService.health();
  }
}
