import { INestApplication } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import request from 'supertest';
import { App } from 'supertest/types';
import { AppModule } from './../src/app.module';

// NOTE: booting AppModule validates env (DATABASE_URL, JWT secrets), so this
// e2e suite needs a configured .env. It is not part of `npm test` (which runs
// only src/*.spec.ts); run it with `npm run test:e2e`.
describe('AppController (e2e)', () => {
  let app: INestApplication<App>;

  beforeEach(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    await app.init();
  });

  it('/health (GET)', () => {
    return request(app.getHttpServer())
      .get('/health')
      .expect(200)
      .expect({ status: 'ok', service: 'artlavka-api' });
  });

  afterEach(async () => {
    await app.close();
  });
});
