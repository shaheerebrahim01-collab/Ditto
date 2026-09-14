import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { NestExpressApplication } from '@nestjs/platform-express';
import helmet from 'helmet';
import { AppModule } from './app.module';
import { getCorsOptions } from './cors-options';

async function bootstrap() {
  // rawBody: true exposes req.rawBody on every request — needed only by
  // POST /payments/webhook, which must verify Stripe's signature against
  // the exact raw bytes rather than the JSON-parsed body. bodyParser: false
  // + the explicit useBodyParser calls below are the supported way to keep
  // that rawBody wiring while also setting an explicit size limit, rather
  // than relying on body-parser's implicit default.
  const app = await NestFactory.create<NestExpressApplication>(AppModule, {
    rawBody: true,
    bodyParser: false,
  });
  app.useBodyParser('json', { limit: '1mb' });
  app.useBodyParser('urlencoded', { extended: true, limit: '1mb' });

  app.use(helmet());
  app.enableCors(getCorsOptions());

  app.useGlobalPipes(new ValidationPipe({ whitelist: true, transform: true }));

  const port = process.env.PORT ? parseInt(process.env.PORT, 10) : 3000;
  await app.listen(port);
  // eslint-disable-next-line no-console
  console.log(`Ditto API running on port ${port}`);
}
bootstrap();
