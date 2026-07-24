import { createParamDecorator, ExecutionContext } from '@nestjs/common';

// Use as a parameter: me(@CurrentUser() user) — instead of digging into
// the raw request object every time.
export const CurrentUser = createParamDecorator(
  (_: unknown, ctx: ExecutionContext) => {
    const request = ctx.switchToHttp().getRequest();
    return request.user;
  },
);
