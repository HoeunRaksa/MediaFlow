import 'package:flutter_test/flutter_test.dart';
import 'package:material_quote_pro/features/ceiling_calculator/domain/ceiling_wire.dart';

void main() {
  test('wire tiers include boundaries and repeat for larger ceilings', () {
    for (final (area, length, price) in <(double, int, double)>[
      (0, 0, 0),
      (-1, 0, 0),
      (0.1, 250, 5),
      (25, 250, 5),
      (25.01, 500, 10),
      (50, 500, 10),
      (50.01, 1000, 15),
      (100, 1000, 15),
      (125, 1250, 20),
      (150, 1500, 25),
      (200, 2000, 30),
      (225, 2250, 35),
      (300, 3000, 45),
    ]) {
      final wire = CeilingWire.forArea(area);
      expect(wire.lengthM, length, reason: '$area m²');
      expect(wire.price, price, reason: '$area m²');
    }
  });
}
