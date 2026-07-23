import { Module } from '@nestjs/common';

// AuthModule owns everything under /auth. Empty by design at this phase —
// see docs/ROADMAP.md for when this module's endpoints land.
@Module({})
export class AuthModule {}
