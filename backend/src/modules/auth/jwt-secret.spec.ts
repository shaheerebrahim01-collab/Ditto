import { getJwtSecret } from './jwt-secret';

describe('getJwtSecret', () => {
  const original = process.env.JWT_SECRET;

  afterEach(() => {
    if (original === undefined) delete process.env.JWT_SECRET;
    else process.env.JWT_SECRET = original;
  });

  it('returns the real secret when set', () => {
    process.env.JWT_SECRET = 'a-real-secret';
    expect(getJwtSecret()).toBe('a-real-secret');
  });

  it('throws rather than silently falling back to a known default when unset', () => {
    delete process.env.JWT_SECRET;
    expect(() => getJwtSecret()).toThrow(/JWT_SECRET is not set/);
  });
});
