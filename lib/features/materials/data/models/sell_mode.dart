class SellMode {
  const SellMode({
    required this.id,
    required this.nameKhmer,
    required this.nameEnglish,
    required this.description,
    required this.active,
  });

  final String id;
  final String nameKhmer;
  final String nameEnglish;
  final String description;
  final bool active;

  String get label => '$nameEnglish / $nameKhmer';

  SellMode copyWith({
    String? id,
    String? nameKhmer,
    String? nameEnglish,
    String? description,
    bool? active,
  }) {
    return SellMode(
      id: id ?? this.id,
      nameKhmer: nameKhmer ?? this.nameKhmer,
      nameEnglish: nameEnglish ?? this.nameEnglish,
      description: description ?? this.description,
      active: active ?? this.active,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nameKhmer': nameKhmer,
      'nameEnglish': nameEnglish,
      'description': description,
      'active': active,
    };
  }

  factory SellMode.fromJson(Map<String, dynamic> json) {
    return SellMode(
      id: json['id'] as String,
      nameKhmer: json['nameKhmer'] as String,
      nameEnglish: json['nameEnglish'] as String,
      description: json['description'] as String? ?? '',
      active: json['active'] as bool? ?? true,
    );
  }
}
