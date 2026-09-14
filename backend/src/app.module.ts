import { Module } from '@nestjs/common';
import { APP_GUARD } from '@nestjs/core';
import { ConfigModule } from '@nestjs/config';
import { ScheduleModule } from '@nestjs/schedule';
import { ThrottlerGuard, ThrottlerModule } from '@nestjs/throttler';
import { PrismaModule } from './prisma/prisma.module';
import { HealthModule } from './health/health.module';
import { AuthModule } from './modules/auth/auth.module';
import { UsersModule } from './modules/users/users.module';
import { BusinessApplicationsModule } from './modules/business-applications/business-applications.module';
import { TailorsModule } from './modules/tailors/tailors.module';
import { MeasurementsModule } from './modules/measurements/measurements.module';
import { MeasurementVisitsModule } from './modules/measurement-visits/measurement-visits.module';
import { RentalShopsModule } from './modules/rental-shops/rental-shops.module';
import { OrdersModule } from './modules/orders/orders.module';
import { RentalsModule } from './modules/rentals/rentals.module';
import { PaymentsModule } from './modules/payments/payments.module';
import { MessagingModule } from './modules/messaging/messaging.module';
import { NotificationsModule } from './modules/notifications/notifications.module';
import { ReviewsModule } from './modules/reviews/reviews.module';
import { StylingModule } from './modules/styling/styling.module';
import { AdminModule } from './modules/admin/admin.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    ScheduleModule.forRoot(),
    // Per-route, per-IP (see ThrottlerGuard.generateKey — it hashes
    // controller+handler+IP, so this budget is independent per endpoint,
    // not one shared bucket across the whole API). 100 req/min is generous
    // for real usage and for the e2e suite; individual sensitive routes
    // (auth/firebase, styling/recommend) override it tighter with
    // @Throttle() where they're defined.
    ThrottlerModule.forRoot([{ name: 'default', ttl: 60000, limit: 100 }]),
    PrismaModule,
    HealthModule,
    AuthModule,
    UsersModule,
    BusinessApplicationsModule,
    TailorsModule,
    MeasurementsModule,
    MeasurementVisitsModule,
    RentalShopsModule,
    OrdersModule,
    RentalsModule,
    PaymentsModule,
    MessagingModule,
    NotificationsModule,
    ReviewsModule,
    StylingModule,
    AdminModule,
  ],
  providers: [{ provide: APP_GUARD, useClass: ThrottlerGuard }],
})
export class AppModule {}
