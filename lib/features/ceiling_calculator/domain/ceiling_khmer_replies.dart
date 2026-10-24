import 'dart:math';

/// Formatted snapshot of the existing ceiling estimate, without recalculation.
class CeilingReplyData {
  CeilingReplyData({required this.priceRange, required List<String> details})
    : details = List.unmodifiable(details);

  final String priceRange;
  final List<String> details;
  String get signature => [priceRange, ...details].join('\n');
}

class CeilingKhmerReplies {
  CeilingKhmerReplies({Random? random}) : _random = random ?? Random() {
    next();
  }

  final Random _random;
  int? _template;
  int? _emoji;
  bool _inlinePrice = false;
  bool _closing = false;

  static const templates = [
    ('បាទបង', 'តម្លៃសរុបប្រហែល'),
    ('សួស្តីបង', 'តម្លៃប៉ាន់ស្មានសរុបប្រហែល'),
    ('បាទបង', 'សម្រាប់ពិដាន 60×60 នេះ តម្លៃសរុបប្រហែល'),
    ('អរគុណបងដែលបានសួរ', 'តម្លៃសរុបប៉ាន់ស្មានប្រហែល'),
    ('បាទបង', 'នេះជាតម្លៃប៉ាន់ស្មានសម្រាប់ពិដាន 60×60'),
    ('សួស្តីបង', 'សម្រាប់ទំហំដែលបានបញ្ចូល តម្លៃសរុបប្រហែល'),
    ('បាទបង', 'ប៉ាន់ស្មានតម្លៃសរុបប្រហែល'),
    ('អរគុណសម្រាប់ការសាកសួរបង', 'តម្លៃពិដានសរុបប្រហែល'),
    ('សួស្តីបង', 'នេះជាព័ត៌មានប៉ាន់ស្មាន តម្លៃសរុបប្រហែល'),
    ('បាទបង', 'តាមទំហំបន្ទប់នេះ តម្លៃប៉ាន់ស្មានសរុបប្រហែល'),
    ('អរគុណបង', 'សម្រាប់ពិដាន 60×60 តម្លៃប៉ាន់ស្មានសរុបប្រហែល'),
    ('សួស្តីបង', 'ខាងក្រោមនេះជាការប៉ាន់ស្មាន តម្លៃសរុបប្រហែល'),
    ('បាទបង', 'សូមជម្រាបតម្លៃប៉ាន់ស្មានសរុបប្រហែល'),
    ('អរគុណបងដែលបានសួរណា', 'តម្លៃសរុបសម្រាប់ពិដាននេះប្រហែល'),
    ('សួស្តីបង', 'តាមការគណនា តម្លៃសរុបប្រហែល'),
    ('បាទបង', 'សម្រាប់ផ្ទៃពិដាននេះ តម្លៃប៉ាន់ស្មានប្រហែល'),
    ('អរគុណបងសម្រាប់ការសាកសួរ', 'នេះជាតម្លៃប៉ាន់ស្មានសរុប'),
    ('សួស្តីបង', 'សូមជម្រាបព័ត៌មានពិដាន 60×60 តម្លៃសរុបប្រហែល'),
    ('បាទបង', 'ខាងក្រោមជាព័ត៌មានលម្អិត តម្លៃប៉ាន់ស្មានសរុបប្រហែល'),
    ('សួស្តីបង', 'សម្រាប់ការប៉ាន់ស្មាននេះ តម្លៃសរុបប្រហែល'),
  ];
  static const emojis = ['🙏', '😊', '🥰', '❤️', '🤍', '💙', '🌷', '✅'];

  void next() {
    _template = _different(templates.length, _template);
    _emoji = _different(emojis.length, _emoji);
    _inlinePrice = _random.nextBool();
    _closing = _random.nextBool();
  }

  int _different(int length, int? previous) {
    if (previous == null) return _random.nextInt(length);
    final index = _random.nextInt(length - 1);
    return index >= previous ? index + 1 : index;
  }

  String render(CeilingReplyData data) {
    final (greeting, intro) = templates[_template!];
    return [
      '$greeting ${emojis[_emoji!]}',
      if (_inlinePrice)
        '$intro៖ ${data.priceRange}'
      else ...[
        intro,
        data.priceRange,
      ],
      ...data.details,
      if (_closing) 'អរគុណបង។',
    ].join('\n');
  }
}
