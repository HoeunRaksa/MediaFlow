class MaterialItem {
  const MaterialItem({
    required this.id,
    required this.khmerName,
    required this.englishName,
    required this.spec,
    required this.unitId,
    required this.unitKhmer,
    required this.unitEnglish,
    required this.categoryId,
    required this.categoryKhmer,
    required this.categoryEnglish,
    required this.formulaTypeId,
    required this.coverageValue,
    required this.multiplierValue,
    required this.fixedQuantity,
    required this.itemsPerBox,
    required this.active,
    required this.includedByDefault,
    required this.showInCustomerQuote,
    required this.showInPickList,
    required this.isOptionalAddon,
    required this.isServiceOnly,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
    this.code,
    this.productFamilyId,
    this.widthMm,
    this.thicknessMm,
    this.lengthMm,
    this.piecesPerBundle,
    this.notes,
    this.designCodes = const [],
    this.imagePath,
  });

  final String id;
  final String khmerName;
  final String englishName;
  final String spec;
  final String unitId;
  final String unitKhmer;
  final String unitEnglish;
  final String categoryId;
  final String categoryKhmer;
  final String categoryEnglish;
  final String formulaTypeId;
  final double? coverageValue;
  final double? multiplierValue;
  final double? fixedQuantity;
  final int? itemsPerBox;
  final bool active;
  final bool includedByDefault;
  final bool showInCustomerQuote;
  final bool showInPickList;
  final bool isOptionalAddon;
  final bool isServiceOnly;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? code;
  final String? productFamilyId;
  final double? widthMm;
  final double? thicknessMm;
  final double? lengthMm;
  final int? piecesPerBundle;
  final String? notes;
  final List<String> designCodes;
  final String? imagePath;

  String get displayName {
    final specText = spec.trim().isEmpty ? '' : ' $spec';
    return '$khmerName$specText / $englishName$specText';
  }

  MaterialItem copyWith({
    String? id,
    String? khmerName,
    String? englishName,
    String? spec,
    String? unitId,
    String? unitKhmer,
    String? unitEnglish,
    String? categoryId,
    String? categoryKhmer,
    String? categoryEnglish,
    String? formulaTypeId,
    double? coverageValue,
    bool clearCoverageValue = false,
    double? multiplierValue,
    bool clearMultiplierValue = false,
    double? fixedQuantity,
    bool clearFixedQuantity = false,
    int? itemsPerBox,
    bool clearItemsPerBox = false,
    bool? active,
    bool? includedByDefault,
    bool? showInCustomerQuote,
    bool? showInPickList,
    bool? isOptionalAddon,
    bool? isServiceOnly,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? code,
    bool clearCode = false,
    String? productFamilyId,
    bool clearProductFamilyId = false,
    double? widthMm,
    bool clearWidthMm = false,
    double? thicknessMm,
    bool clearThicknessMm = false,
    double? lengthMm,
    bool clearLengthMm = false,
    int? piecesPerBundle,
    bool clearPiecesPerBundle = false,
    String? notes,
    bool clearNotes = false,
    List<String>? designCodes,
    String? imagePath,
    bool clearImagePath = false,
  }) {
    return MaterialItem(
      id: id ?? this.id,
      khmerName: khmerName ?? this.khmerName,
      englishName: englishName ?? this.englishName,
      spec: spec ?? this.spec,
      unitId: unitId ?? this.unitId,
      unitKhmer: unitKhmer ?? this.unitKhmer,
      unitEnglish: unitEnglish ?? this.unitEnglish,
      categoryId: categoryId ?? this.categoryId,
      categoryKhmer: categoryKhmer ?? this.categoryKhmer,
      categoryEnglish: categoryEnglish ?? this.categoryEnglish,
      formulaTypeId: formulaTypeId ?? this.formulaTypeId,
      coverageValue: clearCoverageValue
          ? null
          : coverageValue ?? this.coverageValue,
      multiplierValue: clearMultiplierValue
          ? null
          : multiplierValue ?? this.multiplierValue,
      fixedQuantity: clearFixedQuantity
          ? null
          : fixedQuantity ?? this.fixedQuantity,
      itemsPerBox: clearItemsPerBox ? null : itemsPerBox ?? this.itemsPerBox,
      active: active ?? this.active,
      includedByDefault: includedByDefault ?? this.includedByDefault,
      showInCustomerQuote: showInCustomerQuote ?? this.showInCustomerQuote,
      showInPickList: showInPickList ?? this.showInPickList,
      isOptionalAddon: isOptionalAddon ?? this.isOptionalAddon,
      isServiceOnly: isServiceOnly ?? this.isServiceOnly,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      code: clearCode ? null : code ?? this.code,
      productFamilyId: clearProductFamilyId
          ? null
          : productFamilyId ?? this.productFamilyId,
      widthMm: clearWidthMm ? null : widthMm ?? this.widthMm,
      thicknessMm: clearThicknessMm ? null : thicknessMm ?? this.thicknessMm,
      lengthMm: clearLengthMm ? null : lengthMm ?? this.lengthMm,
      piecesPerBundle: clearPiecesPerBundle
          ? null
          : piecesPerBundle ?? this.piecesPerBundle,
      notes: clearNotes ? null : notes ?? this.notes,
      designCodes: designCodes ?? this.designCodes,
      imagePath: clearImagePath ? null : imagePath ?? this.imagePath,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'khmerName': khmerName,
      'englishName': englishName,
      'spec': spec,
      'unitId': unitId,
      'unitKhmer': unitKhmer,
      'unitEnglish': unitEnglish,
      'categoryId': categoryId,
      'categoryKhmer': categoryKhmer,
      'categoryEnglish': categoryEnglish,
      'formulaTypeId': formulaTypeId,
      'coverageValue': coverageValue,
      'multiplierValue': multiplierValue,
      'fixedQuantity': fixedQuantity,
      'itemsPerBox': itemsPerBox,
      'active': active,
      'includedByDefault': includedByDefault,
      'showInCustomerQuote': showInCustomerQuote,
      'showInPickList': showInPickList,
      'isOptionalAddon': isOptionalAddon,
      'isServiceOnly': isServiceOnly,
      'sortOrder': sortOrder,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'code': code,
      'productFamilyId': productFamilyId,
      'widthMm': widthMm,
      'thicknessMm': thicknessMm,
      'lengthMm': lengthMm,
      'piecesPerBundle': piecesPerBundle,
      'notes': notes,
      'designCodes': designCodes,
      'imagePath': imagePath,
    };
  }

  factory MaterialItem.fromJson(Map<String, dynamic> json) {
    final rawDesignCodes = json['designCodes'];
    final designCodes = rawDesignCodes is List
        ? rawDesignCodes.map((e) => e.toString()).toList()
        : const <String>[];

    return MaterialItem(
      id: json['id'] as String,
      khmerName: json['khmerName'] as String,
      englishName: json['englishName'] as String,
      spec: json['spec'] as String? ?? '',
      unitId: json['unitId'] as String,
      unitKhmer: json['unitKhmer'] as String,
      unitEnglish: json['unitEnglish'] as String,
      categoryId: json['categoryId'] as String,
      categoryKhmer: json['categoryKhmer'] as String,
      categoryEnglish: json['categoryEnglish'] as String,
      formulaTypeId: json['formulaTypeId'] as String,
      coverageValue: (json['coverageValue'] as num?)?.toDouble(),
      multiplierValue: (json['multiplierValue'] as num?)?.toDouble(),
      fixedQuantity: (json['fixedQuantity'] as num?)?.toDouble(),
      itemsPerBox: (json['itemsPerBox'] as num?)?.toInt(),
      active: json['active'] as bool? ?? true,
      includedByDefault: json['includedByDefault'] as bool? ?? false,
      showInCustomerQuote: json['showInCustomerQuote'] as bool? ?? true,
      showInPickList: json['showInPickList'] as bool? ?? true,
      isOptionalAddon: json['isOptionalAddon'] as bool? ?? false,
      isServiceOnly: json['isServiceOnly'] as bool? ?? false,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      code: json['code'] as String?,
      productFamilyId: json['productFamilyId'] as String?,
      widthMm: (json['widthMm'] as num?)?.toDouble(),
      thicknessMm: (json['thicknessMm'] as num?)?.toDouble(),
      lengthMm: (json['lengthMm'] as num?)?.toDouble(),
      piecesPerBundle: (json['piecesPerBundle'] as num?)?.toInt(),
      notes: json['notes'] as String?,
      designCodes: designCodes,
      imagePath: json['imagePath'] as String?,
    );
  }
}
