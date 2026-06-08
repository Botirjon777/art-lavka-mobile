import { ValidationPipe } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { AllExceptionsFilter } from './common/filters/all-exceptions.filter';
import { LoggingInterceptor } from './common/interceptors/logging.interceptor';
import { ResponseTransformInterceptor } from './common/interceptors/response-transform.interceptor';
import { patchBigIntJson } from './common/money';

async function bootstrap(): Promise<void> {
  // Serialize BigInt money as strings everywhere (BACKEND_NODE.md §3/§6).
  patchBigIntJson();

  const app = await NestFactory.create(AppModule);

  // Reject bad/unknown input at the edge (BACKEND_NODE.md §9).
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
      transformOptions: { enableImplicitConversion: true },
    }),
  );

  // Consistent `{ error: { code, message } }` shape for the Flutter ErrorMapper.
  app.useGlobalFilters(new AllExceptionsFilter());
  app.useGlobalInterceptors(
    new LoggingInterceptor(),
    new ResponseTransformInterceptor(),
  );

  // Flutter clients are non-browser, but enable CORS for web/dev tooling.
  app.enableCors();

  const config = app.get(ConfigService);
  const port = config.get<number>('PORT') ?? 3000;
  await app.listen(port);
}

void bootstrap();
