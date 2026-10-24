import 'package:flutter_test/flutter_test.dart';
import 'package:material_quote_pro/features/ceiling_calculator/domain/ceiling_v_extra_calculator.dart';

void main() {
  const calculator = CeilingVExtraCalculator();
  const room = CeilingVRoomGroup(lengthM: 6, widthM: 4.2, roomCount: 3);

  test('calculates exact user requirement case: 5x4m room count 5', () {
    final result = calculator.calculate(
      roomGroups: const [
        CeilingVRoomGroup(lengthM: 5, widthM: 4, roomCount: 5),
      ],
      existingVQuantity: 20,
    );

    expect(result.actualVRequired, 31);
    expect(result.existingVQuantity, 20);
    expect(result.extraVToBuy, 11);
  });

  test('calculates total raw V for identical rooms before half-up rounding', () {
    final result = calculator.calculate(
      roomGroups: const [room],
      existingVQuantity: 15,
    );

    // ((6 + 4.2) * 2 / 2.90) * 3 = 61.2 / 2.90 = 21.1034 -> half-up rounds to 21
    expect(result.actualVRequired, 21);
    expect(result.extraVToBuy, 6);
  });

  test('never returns a negative extra V quantity', () {
    expect(
      calculator
          .calculate(roomGroups: const [room], existingVQuantity: 21)
          .extraVToBuy,
      0,
    );
    expect(
      calculator
          .calculate(roomGroups: const [room], existingVQuantity: 30)
          .extraVToBuy,
      0,
    );
  });

  test('calculates raw V requirement for 2 identical rooms', () {
    final result = calculator.calculate(
      roomGroups: const [
        CeilingVRoomGroup(lengthM: 6, widthM: 4.2, roomCount: 2),
      ],
      existingVQuantity: 0,
    );

    // ((6 + 4.2) * 2 / 2.90) * 2 = 40.8 / 2.90 = 14.0689 -> half-up rounds to 14
    expect(result.actualVRequired, 14);
  });

  test(
    'sums raw group requirements from multiple groups before half-up rounding',
    () {
      final result = calculator.calculate(
        roomGroups: const [
          CeilingVRoomGroup(lengthM: 6, widthM: 4.2, roomCount: 3),
          CeilingVRoomGroup(lengthM: 5, widthM: 4, roomCount: 2),
        ],
        existingVQuantity: 23,
      );

      // group 1: 61.2 / 2.90 = 21.103448...
      // group 2: 36.0 / 2.90 = 12.413793...
      // total raw: 33.517241... -> half-up rounds to 34
      expect(result.actualVRequired, 34);
      expect(result.extraVToBuy, 11);
    },
  );
}
