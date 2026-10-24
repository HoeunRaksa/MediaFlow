class PricingTier {
  const PricingTier({
    required this.id,
    required this.nameKhmer,
    required this.nameEnglish,
    required this.pricingBehaviorId,
    required this.active,
    required this.isDefault,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String nameKhmer;
  final String nameEnglish;
  final String pricingBehaviorId;
  final bool active;
  final bool isDefault;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get label => '$nameEnglish / $nameKhmer';

  PricingTier copyWith({
    String? id,
    String? nameKhmer,
    String? nameEnglish,
    String? pricingBehaviorId,
    bool? active,
    bool? isDefault,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PricingTier(
      id: id ?? this.id,
      nameKhmer: nameKhmer ?? this.nameKhmer,
      nameEnglish: nameEnglish ?? this.nameEnglish,
      pricingBehaviorId: pricingBehaviorId ?? this.pricingBehaviorId,
      active: active ?? this.active,
      isDefault: isDefault ?? this.isDefault,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nameKhmer': nameKhmer,
      'nameEnglish': nameEnglish,
      'pricingBehaviorId': pricingBehaviorId,
      'active': active,
      'isDefault': isDefault,
      'sortOrder': sortOrder,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory PricingTier.fromJson(Map<String, dynamic> json) {
    return PricingTier(
      id: json['id'] as String,
      nameKhmer: json['nameKhmer'] as String,
      nameEnglish: json['nameEnglish'] as String,
      pricingBehaviorId: json['pricingBehaviorId'] as String,
      active: json['active'] as bool? ?? true,
      isDefault: json['isDefault'] as bool? ?? false,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
