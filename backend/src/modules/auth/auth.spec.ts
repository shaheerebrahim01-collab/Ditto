import { Test } from '@nestjs/testing';
import { JwtModule, JwtService } from '@nestjs/jwt';

describe('JWT session tokens', () => {
  let jwt: JwtService;

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({
      imports: [
        JwtModule.register({
          secret: 'test-secret',
          signOptions: { expiresIn: '7d' },
        }),
      ],
    }).compile();
    jwt = moduleRef.get(JwtService);
  });

  it('signs a token that verifies back to the same payload', () => {
    const token = jwt.sign({ sub: 'user_123', role: 'CUSTOMER' });
    const decoded = jwt.verify<{ sub: string; role: string }>(token);
    expect(decoded.sub).toBe('user_123');
    expect(decoded.role).toBe('CUSTOMER');
  });

  it('rejects a token signed with a different secret', () => {
    const otherJwt = new JwtService({ secret: 'wrong-secret' });
    const token = jwt.sign({ sub: 'user_123', role: 'CUSTOMER' });
    expect(() => otherJwt.verify(token)).toThrow();
  });
});
