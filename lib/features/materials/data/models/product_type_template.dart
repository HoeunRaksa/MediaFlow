class ProductTypeTemplate {
  const ProductTypeTemplate({
    required this.id,
    required this.nameKhmer,
    required this.nameEnglish,
    required this.inputModeId,
    required this.active,
    required this.isDefault,
    required this.defaultMaterialRules,
    required this.sortOrder,
  });

  final String id;
  final String nameKhmer;
  final String nameEnglish;
  final String inputModeId;
  final bool active;
  final bool isDefault;
  final List<ProductTemplateMaterialRule> defaultMaterialRules;
  final int sortOrder;

  String get label => '$nameEnglish / $nameKhmer';

  ProductTypeTemplate copyWith({
    String? id,
    String? nameKhmer,
    String? nameEnglish,
    String? inputModeId,
    bool? active,
    bool? isDefault,
    List<ProductTemplateMaterialRule>? defaultMaterialRules,
    int? sortOrder,
  }) {
    return ProductTypeTemplate(
      id: id ?? this.id,
      nameKhmer: nameKhmer ?? this.nameKhmer,
      nameEnglish: nameEnglish ?? this.nameEnglish,
      inputModeId: inputModeId ?? this.inputModeId,
      active: active ?? this.active,
      isDefault: isDefault ?? this.isDefault,
      defaultMaterialRules: defaultMaterialRules ?? this.defaultMaterialRules,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nameKhmer': nameKhmer,
      'nameEnglish': nameEnglish,
      'inputModeId': inputModeId,
      'active': active,
      'isDefault': isDefault,
      'defaultMaterialRules': defaultMaterialRules
          .map((rule) => rule.toJson())
          .toList(),
      'sortOrder': sortOrder,
    };
  }

  factory ProductTypeTemplate.fromJson(Map<String, dynamic> json) {
    return ProductTypeTemplate(
      id: json['id'] as String,
      nameKhmer: json['nameKhmer'] as String,
      nameEnglish: json['nameEnglish'] as String,
      inputModeId: json['inputModeId'] as String,
      active: json['active'] as bool? ?? true,
      isDefault: json['isDefault'] as bool? ?? false,
      defaultMaterialRules:
          (json['defaultMaterialRules'] as List<dynamic>? ?? const [])
              .map(
                (item) => ProductTemplateMaterialRule.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ),
              )
              .toList(growable: false),
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }
}

class ProductTemplateMaterialRule {
  const ProductTemplateMaterialRule({
    required this.materialId,
    required this.includedByDefault,
    required this.allowManualOverride,
    required this.formulaTypeOverrideId,
    required this.coverageValueOverride,
    required this.multiplierValueOverride,
    required this.fixedQuantityOverride,
    required this.defaultSellModeId,
  });

  final String materialId;
  final bool includedByDefault;
  final bool allowManualOverride;
  final String? formulaTypeOverrideId;
  final double? coverageValueOverride;
  final double? multiplierValueOverride;
  final double? fixedQuantityOverride;
  final String defaultSellModeId;

  ProductTemplateMaterialRule copyWith({
    String? materialId,
    bool? includedByDefault,
    bool? allowManualOverride,
    String? formulaTypeOverrideId,
    bool clearFormulaTypeOverrideId = false,
    double? coverageValueOverride,
    bool clearCoverageValueOverride = false,
    double? multiplierValueOverride,
    bool clearMultiplierValueOverride = false,
    double? fixedQuantityOverride,
    bool clearFixedQuantityOverride = false,
    String? defaultSellModeId,
  }) {
    return ProductTemplateMaterialRule(
      materialId: materialId ?? this.materialId,
      includedByDefault: includedByDefault ?? this.includedByDefault,
      allowManualOverride: allowManualOverride ?? this.allowManualOverride,
      formulaTypeOverrideId: clearFormulaTypeOverrideId
          ? null
          : formulaTypeOverrideId ?? this.formulaTypeOverrideId,
      coverageValueOverride: clearCoverageValueOverride
          ? null
          : coverageValueOverride ?? this.coverageValueOverride,
      multiplierValueOverride: clearMultiplierValueOverride
          ? null
          : multiplierValueOverride ?? this.multiplierValueOverride,
      fixedQuantityOverride: clearFixedQuantityOverride
          ? null
          : fixedQuantityOverride ?? this.fixedQuantityOverride,
      defaultSellModeId: defaultSellModeId ?? this.defaultSellModeId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'materialId': materialId,
      'includedByDefault': includedByDefault,
      'allowManualOverride': allowManualOverride,
      'formulaTypeOverrideId': formulaTypeOverrideId,
      'coverageValueOverride': coverageValueOverride,
      'multiplierValueOverride': multiplierValueOverride,
      'fixedQuantityOverride': fixedQuantityOverride,
      'defaultSellModeId': defaultSellModeId,
    };
  }

  factory ProductTemplateMaterialRule.fromJson(Map<String, dynamic> json) {
    return ProductTemplateMaterialRule(
      materialId: json['materialId'] as String,
      includedByDefault: json['includedByDefault'] as bool? ?? true,
      allowManualOverride: json['allowManualOverride'] as bool? ?? true,
      formulaTypeOverrideId: json['formulaTypeOverrideId'] as String?,
      coverageValueOverride: (json['coverageValueOverride'] as num?)
          ?.toDouble(),
      multiplierValueOverride: (json['multiplierValueOverride'] as num?)
          ?.toDouble(),
      fixedQuantityOverride: (json['fixedQuantityOverride'] as num?)
          ?.toDouble(),
      defaultSellModeId: json['defaultSellModeId'] as String,
    );
  }
}
