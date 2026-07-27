import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { RentalShopsController } from './rental-shops.controller';
import { RentalShopsService } from './rental-shops.service';

@Module({
  imports: [AuthModule], // needed so JwtAuthGuard has something to check against
  controllers: [RentalShopsController],
  providers: [RentalShopsService],
})
export class RentalShopsModule {}
