import 'dart:math';

/// The existing PVC-only Khmer wording engine. Price remains text so values
/// such as `$20.5` and `20.X` are preserved exactly in the reply.
class PvcKhmerReplies {
  PvcKhmerReplies({Random? random}) : _random = random ?? Random();

  final Random _random;
  int? _template;
  int? _emoji;

  static const templates = [
    'បាទបង {e} តម្លៃក្នុងមួយសន្លឹក {p} ណាបង។',
    'បាទបង មួយសន្លឹកតម្លៃ {p} បង {e}',
    'សួស្តីបង {e} សម្រាប់មួយសន្លឹក តម្លៃ {p} បង។',
    'បាទបង តម្លៃ {p} ក្នុងមួយសន្លឹកណាបង {e}',
    'អរគុណបងដែលបានសួរ {e} តម្លៃមួយសន្លឹក {p} ណាបង។',
    'សួស្តីបង មួយសន្លឹកមានតម្លៃ {p} ណាបង {e}',
    'បាទបង {e} មួយសន្លឹកគឺ {p} បង។',
    'សម្រាប់តម្លៃវិញ មួយសន្លឹក {p} ណាបង {e}',
    'អរគុណបង {e} មួយសន្លឹកតម្លៃ {p} បង។',
    'បាទបង តម្លៃក្នុងមួយសន្លឹកគឺ {p} {e}',
    'សួស្តីបង {e} តម្លៃគឺ {p} សម្រាប់មួយសន្លឹក។',
    'បាទបង សម្រាប់មួយសន្លឹកគឺតម្លៃ {p} ណាបង {e}',
    'អរគុណដែលបងបានសួរតម្លៃ {e} មួយសន្លឹក {p} បង។',
    'បាទបង {e} ក្នុងមួយសន្លឹកមានតម្លៃ {p}។',
    'សួស្តីបង តម្លៃក្នុងមួយសន្លឹក {p} ណា {e}',
    'មួយសន្លឹកតម្លៃ {p} ណាបង អរគុណបងដែលបានសួរ {e}',
    'បាទបង តម្លៃមួយសន្លឹកគឺ {p} ណា {e}',
    'សួស្តីបង {e} មួយសន្លឹកគឺតម្លៃ {p} ណាបង។',
    'អរគុណសម្រាប់ការសាកសួរបង {e} តម្លៃមួយសន្លឹក {p}។',
    'បាទបង មួយសន្លឹក {p} ណា អរគុណបង {e}',
    'សម្រាប់មួយសន្លឹក តម្លៃ {p} បង {e} អរគុណដែលបានសួរ។',
    'បាទបង {e} តម្លៃគឺ {p} ក្នុងមួយសន្លឹក។',
    'សួស្តីបង មួយសន្លឹក {p} បង {e} អរគុណបង។',
    'បាទបង អរគុណសម្រាប់ការសាកសួរ តម្លៃមួយសន្លឹក {p} ណាបង {e}',
    'អរគុណបងដែលបានសួរណា {e} សម្រាប់មួយសន្លឹកគឺ {p} បង។',
  ];

  static const emojis = ['😊', '🙏', '🥰', '❤️', '🤍', '💕', '🌷', '💙', '✅'];

  static String normalizePrice(String value) =>
      value.trim().replaceAll(RegExp(r'\s+'), ' ');

  String reply(String price) {
    final value = normalizePrice(price);
    if (value.isEmpty) return '';
    final display = value.contains(r'$') ? value : '\$$value';
    return templates[_template ?? 0]
        .replaceAll('{p}', display)
        .replaceAll('{e}', emojis[_emoji ?? 0]);
  }

  void next() {
    _template = _different(templates.length, _template);
    _emoji = _different(emojis.length, _emoji);
  }

  int _different(int count, int? previous) {
    if (previous == null) return _random.nextInt(count);
    final candidate = _random.nextInt(count - 1);
    return candidate >= previous ? candidate + 1 : candidate;
  }
}
