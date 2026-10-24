import 'package:flutter_test/flutter_test.dart';
import 'package:material_quote_pro/core/utils/quantity_rounding.dart';

void main() {
  group('roundCeilingQuantity', () {
    const cases = <({double value, int expected})>[
      (value: 0.4, expected: 0),
      (value: 0.5, expected: 1),
      (value: 1.4, expected: 1),
      (value: 1.5, expected: 2),
      (value: 3.4, expected: 3),
      (value: 3.49, expected: 3),
      (value: 3.5, expected: 4),
      (value: 3.51, expected: 4),
      (value: 8.4, expected: 8),
      (value: 8.5, expected: 9),
      (value: 14.4, expected: 14),
      (value: 14.5, expected: 15),
    ];

    for (final testCase in cases) {
      test('${testCase.value} rounds to ${testCase.expected}', () {
        expect(roundCeilingQuantity(testCase.value), testCase.expected);
      });
    }

    test('normalizes floating-point noise just below an exact half', () {
      expect(roundCeilingQuantity(3.4999999997), 4);
      expect(roundCeilingQuantity(8.499999999999998), 9);
      expect(roundCeilingQuantity(14.500000000000002), 15);
    });
  });
}
