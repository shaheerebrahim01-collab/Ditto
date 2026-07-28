import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
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
})
export class AppModule {}
