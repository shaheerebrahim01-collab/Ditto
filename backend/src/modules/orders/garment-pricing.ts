// Kept in sync by hand with mobile/customer_app/lib/data/garment_builder_options.dart
// — same convention as styling/garment-vocabulary.ts's id lists. Price is
// always computed here from the ids the client sends, never trusted
// directly from the client (an order's price is money; the vocabulary ids
// are the only thing a client gets to choose).
import { BadRequestException } from '@nestjs/common';
import { BUTTON_STYLES, FABRIC_IDS, GARMENT_TYPE_IDS, LAPEL_STYLES } from '../styling/garment-vocabulary';
import { CreateOrderDto } from './dto/create-order.dto';

export const GARMENT_BASE_PRICES: Record<(typeof GARMENT_TYPE_IDS)[number], number> = {
  suit: 250,
  sherwani: 320,
  kurta: 90,
  waistcoat: 70,
  trousers: 60,
  blazer: 180,
  shirt: 50,
  tuxedo: 380,
};

export const FABRIC_PRICE_ADD_ONS: Record<(typeof FABRIC_IDS)[number], number> = {
  charcoal_wool: 0,
  navy_twill: 15,
  ivory_linen: 20,
  slate_grey: 10,
  beige_cotton: 10,
  burgundy_silk: 60,
  midnight_velvet: 75,
  herringbone_black: 35,
};

export const LAPEL_STYLE_PRICES: Record<(typeof LAPEL_STYLES)[number], number> = {
  Notch: 0,
  Peak: 15,
  Shawl: 15,
};

export const BUTTON_STYLE_PRICES: Record<(typeof BUTTON_STYLES)[number], number> = {
  '2-Button': 0,
  '3-Button': 5,
  'Double-Breasted': 20,
};

export const MONOGRAM_PRICE = 10;

// Throws BadRequestException on an unrecognized id rather than silently
// pricing it as 0 — a typo'd garmentTypeId should never produce a free order.
export function computeOrderPrice(dto: CreateOrderDto): number {
  const basePrice = GARMENT_BASE_PRICES[dto.garmentTypeId as (typeof GARMENT_TYPE_IDS)[number]];
  if (basePrice === undefined) throw new BadRequestException(`Unknown garmentTypeId: ${dto.garmentTypeId}`);

  const fabricPrice = FABRIC_PRICE_ADD_ONS[dto.fabricId as (typeof FABRIC_IDS)[number]];
  if (fabricPrice === undefined) throw new BadRequestException(`Unknown fabricId: ${dto.fabricId}`);

  const lapelStyle = dto.lapelStyle ?? 'Notch';
  const lapelPrice = LAPEL_STYLE_PRICES[lapelStyle as (typeof LAPEL_STYLES)[number]];
  if (lapelPrice === undefined) throw new BadRequestException(`Unknown lapelStyle: ${lapelStyle}`);

  const buttonStyle = dto.buttonStyle ?? '2-Button';
  const buttonPrice = BUTTON_STYLE_PRICES[buttonStyle as (typeof BUTTON_STYLES)[number]];
  if (buttonPrice === undefined) throw new BadRequestException(`Unknown buttonStyle: ${buttonStyle}`);

  const monogramFee = dto.monogram && dto.monogram.trim().length > 0 ? MONOGRAM_PRICE : 0;

  return basePrice + fabricPrice + lapelPrice + buttonPrice + monogramFee;
}
