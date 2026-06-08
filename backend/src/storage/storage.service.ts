import { randomUUID } from 'node:crypto';
import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { AppException } from '../common/errors/app.exception';
import { ErrorCode } from '../common/errors/error-codes';
import { AppConstants } from '../config/constants';
import { PrismaService } from '../prisma/prisma.service';
import { Buckets, EXT_BY_MIME, PUBLIC_BUCKETS } from './buckets';

export interface PresignedUpload {
  uploadUrl: string;
  bucket: string;
  path: string;
  publicUrl: string | null;
}

/**
 * Issues presigned URLs for S3-compatible storage (BACKEND_NODE.md §5).
 *
 * Until S3 credentials are configured (`S3_ENDPOINT` unset) this runs in MOCK
 * mode and returns deterministic placeholder URLs, so the upload flow is
 * exercisable end-to-end. The real path will use `@aws-sdk/s3-request-presigner`
 * — swap is localized to this service.
 */
@Injectable()
export class StorageService {
  private readonly mock: boolean;
  private readonly base: string;

  constructor(
    private readonly prisma: PrismaService,
    config: ConfigService,
  ) {
    const endpoint = config.get<string>('S3_ENDPOINT');
    this.mock = !endpoint;
    this.base = endpoint ?? 'https://storage.mock';
  }

  presignUpload(bucket: string, contentType: string): PresignedUpload {
    const ext = EXT_BY_MIME[contentType.toLowerCase()];
    // Print artwork/previews must be PNG/JPG; signatures are lenient.
    if (bucket !== Buckets.signatures && !ext) {
      throw new AppException(
        ErrorCode.uploadWrongFormat,
        'Use a PNG or JPG file',
        422,
      );
    }
    const path = `${randomUUID()}.${ext ?? 'bin'}`;
    return {
      uploadUrl: this.mock
        ? `${this.base}/upload/${bucket}/${path}?mock=1`
        : this.realPutUrl(bucket, path),
      bucket,
      path,
      publicUrl: PUBLIC_BUCKETS.includes(bucket)
        ? `${this.base}/${bucket}/${path}`
        : null,
    };
  }

  /** Short-lived signed GET for a design's private print file (ops/admin only). */
  async presignPrintFile(
    designId: string,
  ): Promise<{ url: string; expiresIn: number }> {
    const design = await this.prisma.design.findUnique({
      where: { id: designId },
      select: { printFilePath: true },
    });
    if (!design) throw AppException.notFound('Design not found');

    const ttl = AppConstants.signedUrlTtlSeconds;
    const url = this.mock
      ? `${this.base}/signed/${Buckets.printFiles}/${design.printFilePath}?ttl=${ttl}`
      : this.realGetUrl(Buckets.printFiles, design.printFilePath);
    return { url, expiresIn: ttl };
  }

  // TODO: implement with @aws-sdk/client-s3 + s3-request-presigner once S3 is
  // configured. Signing is local, so these run offline given endpoint + creds.
  private realPutUrl(bucket: string, path: string): string {
    throw new AppException(
      ErrorCode.server,
      `S3 presign not implemented yet (PUT ${bucket}/${path})`,
      500,
    );
  }

  private realGetUrl(bucket: string, path: string): string {
    throw new AppException(
      ErrorCode.server,
      `S3 presign not implemented yet (GET ${bucket}/${path})`,
      500,
    );
  }
}
