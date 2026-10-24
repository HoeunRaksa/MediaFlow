class MaterialQuantityPriceTier {
  const MaterialQuantityPriceTier({
    required this.id,
    required this.materialId,
    required this.minQuantity,
    required this.unitPriceCents,
    required this.currencyCode,
    required this.sourceDate,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String materialId;
  final int minQuantity;
  final int unitPriceCents;
  final String currencyCode;
  final DateTime sourceDate;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;

  double get unitPrice => unitPriceCents / 100;

  MaterialQuantityPriceTier copyWith({
    String? id,
    String? materialId,
    int? minQuantity,
    int? unitPriceCents,
    String? currencyCode,
    DateTime? sourceDate,
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MaterialQuantityPriceTier(
      id: id ?? this.id,
      materialId: materialId ?? this.materialId,
      minQuantity: minQuantity ?? this.minQuantity,
      unitPriceCents: unitPriceCents ?? this.unitPriceCents,
      currencyCode: currencyCode ?? this.currencyCode,
      sourceDate: sourceDate ?? this.sourceDate,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'materialId': materialId,
      'minQuantity': minQuantity,
      'unitPriceCents': unitPriceCents,
      'currencyCode': currencyCode,
      'sourceDate': sourceDate.toIso8601String(),
      'active': active,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory MaterialQuantityPriceTier.fromJson(Map<String, dynamic> json) {
    return MaterialQuantityPriceTier(
      id: json['id'] as String,
      materialId: json['materialId'] as String,
      minQuantity: (json['minQuantity'] as num).toInt(),
      unitPriceCents: (json['unitPriceCents'] as num).toInt(),
      currencyCode: json['currencyCode'] as String? ?? 'USD',
      sourceDate: DateTime.parse(json['sourceDate'] as String),
      active: json['active'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
