import crypto from 'crypto';
import { PutObjectCommand, S3Client } from '@aws-sdk/client-s3';
import { env } from '../config/env';

export interface StorageProvider {
  upload(buffer: Buffer, contentType: string): Promise<string>;
}

const EXT: Record<string, string> = {
  'image/jpeg': 'jpg',
  'image/png': 'png',
  'image/webp': 'webp',
};

export const ALLOWED_IMAGE_TYPES = Object.keys(EXT);

/** Works with any S3-compatible service (AWS S3, MinIO, R2, Spaces). */
export class S3Storage implements StorageProvider {
  private client = new S3Client({
    region: env.s3.region,
    endpoint: env.s3.endpoint,
    forcePathStyle: !!env.s3.endpoint,
    credentials: { accessKeyId: env.s3.accessKey, secretAccessKey: env.s3.secretKey },
  });

  async upload(buffer: Buffer, contentType: string): Promise<string> {
    const key = `uploads/${crypto.randomUUID()}.${EXT[contentType] ?? 'bin'}`;
    await this.client.send(
      new PutObjectCommand({ Bucket: env.s3.bucket, Key: key, Body: buffer, ContentType: contentType }),
    );
    return `${env.s3.publicUrl.replace(/\/$/, '')}/${key}`;
  }
}

let provider: StorageProvider | undefined;
export const getStorage = (): StorageProvider => (provider ??= new S3Storage());
export const setStorage = (p: StorageProvider) => {
  provider = p;
};
