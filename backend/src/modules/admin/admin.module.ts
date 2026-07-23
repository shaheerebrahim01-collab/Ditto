import { Module } from '@nestjs/common';

// AdminModule owns everything under /admin. Empty by design at this phase —
// see docs/ROADMAP.md for when this module's endpoints land.
@Module({})
export class AdminModule {}
