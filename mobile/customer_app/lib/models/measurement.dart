// Mirrors backend/prisma/schema.prisma's Measurement model.
class Measurement {
  const Measurement({
    required this.id,
    required this.label,
    this.chest,
    this.waist,
    this.hip,
    this.shoulder,
    this.sleeve,
    this.neck,
    this.inseam,
    this.notes,
  });

  factory Measurement.fromJson(Map<String, dynamic> json) => Measurement(
    id: json['id'] as String,
    label: json['label'] as String,
    chest: (json['chest'] as num?)?.toDouble(),
    waist: (json['waist'] as num?)?.toDouble(),
    hip: (json['hip'] as num?)?.toDouble(),
    shoulder: (json['shoulder'] as num?)?.toDouble(),
    sleeve: (json['sleeve'] as num?)?.toDouble(),
    neck: (json['neck'] as num?)?.toDouble(),
    inseam: (json['inseam'] as num?)?.toDouble(),
    notes: json['notes'] as String?,
  );

  final String id;
  final String label;
  final double? chest;
  final double? waist;
  final double? hip;
  final double? shoulder;
  final double? sleeve;
  final double? neck;
  final double? inseam;
  final String? notes;

  Map<String, double> get values => {
    if (chest != null) 'Chest': chest!,
    if (waist != null) 'Waist': waist!,
    if (hip != null) 'Hip': hip!,
    if (shoulder != null) 'Shoulder': shoulder!,
    if (sleeve != null) 'Sleeve': sleeve!,
    if (neck != null) 'Neck': neck!,
    if (inseam != null) 'Inseam': inseam!,
  };
}
