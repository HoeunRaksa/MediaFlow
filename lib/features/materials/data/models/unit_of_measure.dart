class UnitOfMeasure {
  const UnitOfMeasure({
    required this.id,
    required this.nameKhmer,
    required this.nameEnglish,
    required this.abbreviationKhmer,
    required this.abbreviationEnglish,
    required this.active,
    required this.sortOrder,
  });

  final String id;
  final String nameKhmer;
  final String nameEnglish;
  final String abbreviationKhmer;
  final String abbreviationEnglish;
  final bool active;
  final int sortOrder;

  String get label => '$nameEnglish / $nameKhmer';

  UnitOfMeasure copyWith({
    String? id,
    String? nameKhmer,
    String? nameEnglish,
    String? abbreviationKhmer,
    String? abbreviationEnglish,
    bool? active,
    int? sortOrder,
  }) {
    return UnitOfMeasure(
      id: id ?? this.id,
      nameKhmer: nameKhmer ?? this.nameKhmer,
      nameEnglish: nameEnglish ?? this.nameEnglish,
      abbreviationKhmer: abbreviationKhmer ?? this.abbreviationKhmer,
      abbreviationEnglish: abbreviationEnglish ?? this.abbreviationEnglish,
      active: active ?? this.active,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nameKhmer': nameKhmer,
      'nameEnglish': nameEnglish,
      'abbreviationKhmer': abbreviationKhmer,
      'abbreviationEnglish': abbreviationEnglish,
      'active': active,
      'sortOrder': sortOrder,
    };
  }

  factory UnitOfMeasure.fromJson(Map<String, dynamic> json) {
    return UnitOfMeasure(
      id: json['id'] as String,
      nameKhmer: json['nameKhmer'] as String,
      nameEnglish: json['nameEnglish'] as String,
      abbreviationKhmer: json['abbreviationKhmer'] as String,
      abbreviationEnglish: json['abbreviationEnglish'] as String,
      active: json['active'] as bool? ?? true,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }
}
