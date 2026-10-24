import '../../../../core/constants/business_ids.dart';

class MaterialPrice {
  MaterialPrice({
    required this.id,
    required this.materialId,
    required this.priceTypeId,
    required double price,
    required this.currencyCode,
    required this.effectiveFrom,
    required this.effectiveTo,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
    int? priceCents,
  }) : priceCents = priceCents ?? _toCents(price);

  final String id;
  final String materialId;
  final String priceTypeId;
  final int priceCents;
  final String currencyCode;
  final DateTime effectiveFrom;
  final DateTime? effectiveTo;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;

  double get price => priceCents / 100;

  String get pricingTierId => priceTypeId;

  bool isEffectiveAt(DateTime date) {
    final startsBeforeOrNow = !effectiveFrom.isAfter(date);
    final endsAfterNow = effectiveTo == null || effectiveTo!.isAfter(date);
    return active && startsBeforeOrNow && endsAfterNow;
  }

  MaterialPrice copyWith({
    String? id,
    String? materialId,
    String? priceTypeId,
    String? pricingTierId,
    double? price,
    int? priceCents,
    String? currencyCode,
    DateTime? effectiveFrom,
    DateTime? effectiveTo,
    bool clearEffectiveTo = false,
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MaterialPrice(
      id: id ?? this.id,
      materialId: materialId ?? this.materialId,
      priceTypeId: priceTypeId ?? pricingTierId ?? this.priceTypeId,
      price: price ?? this.price,
      priceCents: priceCents ?? (price == null ? this.priceCents : null),
      currencyCode: currencyCode ?? this.currencyCode,
      effectiveFrom: effectiveFrom ?? this.effectiveFrom,
      effectiveTo: clearEffectiveTo ? null : effectiveTo ?? this.effectiveTo,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'materialId': materialId,
      'priceTypeId': priceTypeId,
      'price': price,
      'priceCents': priceCents,
      'currencyCode': currencyCode,
      'effectiveFrom': effectiveFrom.toIso8601String(),
      'effectiveTo': effectiveTo?.toIso8601String(),
      'active': active,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory MaterialPrice.fromJson(Map<String, dynamic> json) {
    return MaterialPrice(
      id: json['id'] as String,
      materialId: json['materialId'] as String,
      priceTypeId: _normalizePriceType(
        json['priceTypeId'] as String? ?? json['pricingTierId'] as String,
      ),
      price:
          (json['price'] as num?)?.toDouble() ??
          ((json['priceCents'] as num).toInt() / 100),
      priceCents: (json['priceCents'] as num?)?.toInt(),
      currencyCode: json['currencyCode'] as String? ?? 'USD',
      effectiveFrom: DateTime.parse(json['effectiveFrom'] as String),
      effectiveTo: json['effectiveTo'] == null
          ? null
          : DateTime.parse(json['effectiveTo'] as String),
      active: json['active'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

int _toCents(double value) => (value * 100).round();

String _normalizePriceType(String value) {
  return switch (value) {
    'retail' => PriceTypeIds.unitPrice,
    'wholesale' => PriceTypeIds.wholesaleUnitPrice,
    'box' => PriceTypeIds.boxPrice,
    _ => value,
  };
}
