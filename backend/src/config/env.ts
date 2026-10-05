import 'dotenv/config';

const isProd = process.env.NODE_ENV === 'production';

function secret(name: string, fallback: string): string {
  const v = process.env[name];
  if (v && v.length >= 32) return v;
  if (isProd) throw new Error(`${name} must be set (min 32 chars) in production`);
  return fallback;
}

export const env = {
  isProd,
  port: Number(process.env.PORT ?? 4000),
  corsOrigin: process.env.CORS_ORIGIN ?? '*',
  accessSecret: secret('JWT_ACCESS_SECRET', 'dev-access-secret-dev-access-secret-1234'),
  refreshSecret: secret('JWT_REFRESH_SECRET', 'dev-refresh-secret-dev-refresh-secret-1234'),
    refreshTtlDays: 30,
  adminEmails: (process.env.ADMIN_EMAILS ?? '').split(',').map((e) => e.trim().toLowerCase()).filter(Boolean),
  ai: {
    baseUrl: process.env.AI_BASE_URL ?? 'https://api.openai.com/v1',
    apiKey: process.env.AI_API_KEY ?? '',
    model: process.env.AI_MODEL ?? 'gpt-4o-mini',
    systemPrompt:
      process.env.AI_SYSTEM_PROMPT ??
      'You are Sikshak, a friendly AI tutor for students in Nepal (SEE, +2, Bachelor level). Prefer the provided course notes. Answer in the language the student uses (English or Nepali). Explain step by step, keep it concise, and say so honestly when you are not sure.',
  },
  s3: {
    endpoint: process.env.S3_ENDPOINT,
    region: process.env.S3_REGION ?? 'us-east-1',
    bucket: process.env.S3_BUCKET ?? '',
    accessKey: process.env.S3_ACCESS_KEY ?? '',
    secretKey: process.env.S3_SECRET_KEY ?? '',
    publicUrl: process.env.S3_PUBLIC_URL ?? '',
  },
};
