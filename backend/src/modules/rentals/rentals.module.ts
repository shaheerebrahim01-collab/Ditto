import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { RentalsController } from './rentals.controller';
import { RentalsService } from './rentals.service';

@Module({
  imports: [AuthModule], // needed so JwtAuthGuard has something to check against
  controllers: [RentalsController],
  providers: [RentalsService],
})
export class RentalsModule {}
