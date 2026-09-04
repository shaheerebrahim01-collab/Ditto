import { BadRequestException } from '@nestjs/common';
import { computeOrderPrice } from './garment-pricing';
import { CreateOrderDto } from './dto/create-order.dto';

function dto(overrides: Partial<CreateOrderDto>): CreateOrderDto {
  return Object.assign(new CreateOrderDto(), {
    tailorId: 'tailor_1',
    garmentTypeId: 'suit',
    fabricId: 'charcoal_wool',
    ...overrides,
  });
}

describe('computeOrderPrice', () => {
  it('prices the cheapest possible combination at just the garment base price', () => {
    expect(computeOrderPrice(dto({ garmentTypeId: 'shirt', fabricId: 'charcoal_wool' }))).toBe(50);
  });

  it('defaults lapelStyle/buttonStyle to their free options when omitted', () => {
    // suit(250) + charcoal_wool(0) + Notch(0, default) + 2-Button(0, default)
    expect(computeOrderPrice(dto({}))).toBe(250);
  });

  it('adds every upgrade on top of the base price', () => {
    // suit(250) + burgundy_silk(60) + Peak(15) + Double-Breasted(20) + monogram(10) = 355
    expect(
      computeOrderPrice(
        dto({
          fabricId: 'burgundy_silk',
          lapelStyle: 'Peak',
          buttonStyle: 'Double-Breasted',
          monogram: 'A.K.',
        }),
      ),
    ).toBe(355);
  });

  it('only charges the monogram fee when non-empty text is actually given', () => {
    expect(computeOrderPrice(dto({ monogram: '' }))).toBe(250);
    expect(computeOrderPrice(dto({ monogram: '   ' }))).toBe(250);
  });

  it('rejects an unrecognized garmentTypeId rather than silently pricing it as 0', () => {
    expect(() => computeOrderPrice(dto({ garmentTypeId: 'spacesuit' }))).toThrow(BadRequestException);
  });

  it('rejects an unrecognized fabricId', () => {
    expect(() => computeOrderPrice(dto({ fabricId: 'gold_lame' }))).toThrow(BadRequestException);
  });

  it('every real garment type has a positive base price', () => {
    const garmentTypeIds = ['suit', 'sherwani', 'kurta', 'waistcoat', 'trousers', 'blazer', 'shirt', 'tuxedo'];
    for (const garmentTypeId of garmentTypeIds) {
      expect(computeOrderPrice(dto({ garmentTypeId }))).toBeGreaterThan(0);
    }
  });
});
