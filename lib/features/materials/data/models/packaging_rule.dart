class PackagingRule {
  const PackagingRule({
    required this.id,
    required this.materialId,
    required this.itemsPerBox,
    required this.boxUnitNameKhmer,
    required this.boxUnitNameEnglish,
    required this.size,
    required this.length,
    required this.note,
    required this.active,
    required this.updatedAt,
  });

  final String id;
  final String materialId;
  final int itemsPerBox;
  final String boxUnitNameKhmer;
  final String boxUnitNameEnglish;
  final String size;
  final String length;
  final String note;
  final bool active;
  final DateTime updatedAt;

  PackagingRule copyWith({
    String? id,
    String? materialId,
    int? itemsPerBox,
    String? boxUnitNameKhmer,
    String? boxUnitNameEnglish,
    String? size,
    String? length,
    String? note,
    bool? active,
    DateTime? updatedAt,
  }) {
    return PackagingRule(
      id: id ?? this.id,
      materialId: materialId ?? this.materialId,
      itemsPerBox: itemsPerBox ?? this.itemsPerBox,
      boxUnitNameKhmer: boxUnitNameKhmer ?? this.boxUnitNameKhmer,
      boxUnitNameEnglish: boxUnitNameEnglish ?? this.boxUnitNameEnglish,
      size: size ?? this.size,
      length: length ?? this.length,
      note: note ?? this.note,
      active: active ?? this.active,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'materialId': materialId,
      'itemsPerBox': itemsPerBox,
      'boxUnitNameKhmer': boxUnitNameKhmer,
      'boxUnitNameEnglish': boxUnitNameEnglish,
      'size': size,
      'length': length,
      'note': note,
      'active': active,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory PackagingRule.fromJson(Map<String, dynamic> json) {
    return PackagingRule(
      id: json['id'] as String,
      materialId: json['materialId'] as String,
      itemsPerBox: (json['itemsPerBox'] as num).toInt(),
      boxUnitNameKhmer: json['boxUnitNameKhmer'] as String? ?? 'កេស',
      boxUnitNameEnglish: json['boxUnitNameEnglish'] as String? ?? 'Box',
      size: json['size'] as String? ?? '',
      length: json['length'] as String? ?? '',
      note: json['note'] as String? ?? '',
      active: json['active'] as bool? ?? true,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
