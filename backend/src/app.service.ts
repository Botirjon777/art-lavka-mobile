import { Injectable } from '@nestjs/common';

@Injectable()
export class AppService {
  health(): { status: string; service: string } {
    return { status: 'ok', service: 'artlavka-api' };
  }
}
