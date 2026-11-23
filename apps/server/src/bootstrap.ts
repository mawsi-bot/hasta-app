import { INestApplication, ValidationPipe } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { DocumentBuilder, SwaggerModule, type OpenAPIObject } from '@nestjs/swagger';
import { AppModule } from './app.module';
import type { Env } from './config/env';
import type { Secrets } from './config/secrets';

export async function createApp(env: Env, secrets: Secrets): Promise<INestApplication> {
  const app = await NestFactory.create(AppModule.forRoot(env, secrets), { logger: ['error', 'warn'], bodyParser: true });
  configureApp(app);
  return app;
}

export function configureApp(app: INestApplication): void {
  app.setGlobalPrefix('v1');
  app.useGlobalPipes(new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true }));
  const http = app.getHttpAdapter().getInstance() as { disable?: (k: string) => void; set?: (k: string, v: unknown) => void };
  http.disable?.('x-powered-by');
  http.set?.('trust proxy', 1);
}

export function buildOpenApi(app: INestApplication): OpenAPIObject {
  const cfg = new DocumentBuilder()
    .setTitle('Hasta API')
    .setVersion('1.0.0')
    .setDescription('Hasta v1.0.0 — guest-first identity. No OTP/SMS, no Google/Apple sign-in (linking only).')
    .addBearerAuth()
    .build();
  return SwaggerModule.createDocument(app, cfg);
}
