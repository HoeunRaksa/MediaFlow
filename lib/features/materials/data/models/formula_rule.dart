class FormulaRule {
  const FormulaRule({
    required this.id,
    required this.formulaTypeId,
    required this.nameKhmer,
    required this.nameEnglish,
    required this.description,
    required this.requiresCoverageValue,
    required this.requiresMultiplierValue,
    required this.requiresFixedQuantity,
    required this.requiresManualQuantity,
    required this.active,
    required this.sortOrder,
  });

  final String id;
  final String formulaTypeId;
  final String nameKhmer;
  final String nameEnglish;
  final String description;
  final bool requiresCoverageValue;
  final bool requiresMultiplierValue;
  final bool requiresFixedQuantity;
  final bool requiresManualQuantity;
  final bool active;
  final int sortOrder;

  String get label => '$nameEnglish / $nameKhmer';

  FormulaRule copyWith({
    String? id,
    String? formulaTypeId,
    String? nameKhmer,
    String? nameEnglish,
    String? description,
    bool? requiresCoverageValue,
    bool? requiresMultiplierValue,
    bool? requiresFixedQuantity,
    bool? requiresManualQuantity,
    bool? active,
    int? sortOrder,
  }) {
    return FormulaRule(
      id: id ?? this.id,
      formulaTypeId: formulaTypeId ?? this.formulaTypeId,
      nameKhmer: nameKhmer ?? this.nameKhmer,
      nameEnglish: nameEnglish ?? this.nameEnglish,
      description: description ?? this.description,
      requiresCoverageValue:
          requiresCoverageValue ?? this.requiresCoverageValue,
      requiresMultiplierValue:
          requiresMultiplierValue ?? this.requiresMultiplierValue,
      requiresFixedQuantity:
          requiresFixedQuantity ?? this.requiresFixedQuantity,
      requiresManualQuantity:
          requiresManualQuantity ?? this.requiresManualQuantity,
      active: active ?? this.active,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'formulaTypeId': formulaTypeId,
      'nameKhmer': nameKhmer,
      'nameEnglish': nameEnglish,
      'description': description,
      'requiresCoverageValue': requiresCoverageValue,
      'requiresMultiplierValue': requiresMultiplierValue,
      'requiresFixedQuantity': requiresFixedQuantity,
      'requiresManualQuantity': requiresManualQuantity,
      'active': active,
      'sortOrder': sortOrder,
    };
  }

  factory FormulaRule.fromJson(Map<String, dynamic> json) {
    return FormulaRule(
      id: json['id'] as String,
      formulaTypeId: json['formulaTypeId'] as String,
      nameKhmer: json['nameKhmer'] as String,
      nameEnglish: json['nameEnglish'] as String,
      description: json['description'] as String? ?? '',
      requiresCoverageValue: json['requiresCoverageValue'] as bool? ?? false,
      requiresMultiplierValue:
          json['requiresMultiplierValue'] as bool? ?? false,
      requiresFixedQuantity: json['requiresFixedQuantity'] as bool? ?? false,
      requiresManualQuantity: json['requiresManualQuantity'] as bool? ?? false,
      active: json['active'] as bool? ?? true,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }
}
