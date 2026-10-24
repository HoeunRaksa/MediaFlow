class MaterialCategory {
  const MaterialCategory({
    required this.id,
    required this.nameKhmer,
    required this.nameEnglish,
    required this.active,
    required this.sortOrder,
  });

  final String id;
  final String nameKhmer;
  final String nameEnglish;
  final bool active;
  final int sortOrder;

  String get label => '$nameEnglish / $nameKhmer';

  MaterialCategory copyWith({
    String? id,
    String? nameKhmer,
    String? nameEnglish,
    bool? active,
    int? sortOrder,
  }) {
    return MaterialCategory(
      id: id ?? this.id,
      nameKhmer: nameKhmer ?? this.nameKhmer,
      nameEnglish: nameEnglish ?? this.nameEnglish,
      active: active ?? this.active,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nameKhmer': nameKhmer,
      'nameEnglish': nameEnglish,
      'active': active,
      'sortOrder': sortOrder,
    };
  }

  factory MaterialCategory.fromJson(Map<String, dynamic> json) {
    return MaterialCategory(
      id: json['id'] as String,
      nameKhmer: json['nameKhmer'] as String,
      nameEnglish: json['nameEnglish'] as String,
      active: json['active'] as bool? ?? true,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }
}
