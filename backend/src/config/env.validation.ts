import { plainToInstance } from 'class-transformer';
import {
  IsIn,
  IsInt,
  IsOptional,
  IsString,
  MinLength,
  validateSync,
} from 'class-validator';

/**
 * Validated environment. `ConfigModule.forRoot({ validate })` runs this at
 * bootstrap and fails fast if required vars are missing/malformed.
 */
export class EnvVars {
  @IsOptional()
  @IsInt()
  PORT: number = 3000;

  @IsIn(['development', 'test', 'production'])
  @IsOptional()
  NODE_ENV: string = 'development';

  @IsString()
  @MinLength(1)
  DATABASE_URL!: string;

  @IsString()
  @MinLength(16)
  JWT_ACCESS_SECRET!: string;

  @IsString()
  @MinLength(16)
  JWT_REFRESH_SECRET!: string;

  @IsOptional()
  @IsString()
  ACCESS_TOKEN_TTL: string = '15m';

  @IsOptional()
  @IsString()
  REFRESH_TOKEN_TTL: string = '30d';

  /** When 'true', the auth module uses a mock SMS provider (logs the code). */
  @IsOptional()
  @IsString()
  MOCK_SMS: string = 'true';

  // --- Cloudinary (signed uploads for designer print files) ----------------
  /** 'true' enables signed Cloudinary uploads; otherwise storage stays mock. */
  @IsOptional()
  @IsString()
  USE_CLOUDINARY: string = 'false';

  @IsOptional()
  @IsString()
  CLOUDINARY_CLOUD_NAME?: string;

  @IsOptional()
  @IsString()
  CLOUDINARY_API_KEY?: string;

  @IsOptional()
  @IsString()
  CLOUDINARY_API_SECRET?: string;
}

export function validateEnv(config: Record<string, unknown>): EnvVars {
  const validated = plainToInstance(EnvVars, config, {
    enableImplicitConversion: true,
  });
  const errors = validateSync(validated, { skipMissingProperties: false });
  if (errors.length > 0) {
    throw new Error(
      `Invalid environment configuration:\n${errors
        .map(
          (e) =>
            `  - ${e.property}: ${Object.values(e.constraints ?? {}).join(', ')}`,
        )
        .join('\n')}`,
    );
  }
  return validated;
}
