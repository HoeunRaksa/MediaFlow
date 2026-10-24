import 'package:flutter_test/flutter_test.dart';
import 'package:material_quote_pro/core/constants/business_ids.dart';
import 'package:material_quote_pro/features/materials/domain/delivery_calculation_engine.dart';

void main() {
  group('Delivery Calculation Engine', () {
    test('DK01 per box delivery', () {
      final lines = [
        const DeliveryLineData(packagingFullBoxes: 2, packagingLooseItems: 5),
      ];
      final result = calculateDelivery(
        deliveryModeId: DeliveryModeIds.perBoxDelivery,
        deliveryPayerId: DeliveryPayerIds.customerPays,
        deliveryRate: 1,
        lines: lines,
      );
      expect(result.deliveryFeeTotal, 2);
    });

    test('Loose-only delivery', () {
      final lines = [
        const DeliveryLineData(packagingFullBoxes: 0, packagingLooseItems: 5),
      ];
      final result = calculateDelivery(
        deliveryModeId: DeliveryModeIds.perBoxDelivery,
        deliveryPayerId: DeliveryPayerIds.customerPays,
        deliveryRate: 1,
        lines: lines,
      );
      expect(result.totalFullBoxes, 0);
      expect(result.totalLooseItems, 5);
      expect(result.deliveryFeeTotal, 0);
    });

    test('Ceiling area 100 per box delivery', () {
      final lines = [
        const DeliveryLineData(packagingFullBoxes: 23, packagingLooseItems: 2),
        const DeliveryLineData(packagingFullBoxes: 1, packagingLooseItems: 0),
        const DeliveryLineData(packagingFullBoxes: 3, packagingLooseItems: 0),
        const DeliveryLineData(packagingFullBoxes: 0, packagingLooseItems: 20),
      ];
      final result = calculateDelivery(
        deliveryModeId: DeliveryModeIds.perBoxDelivery,
        deliveryPayerId: DeliveryPayerIds.customerPays,
        deliveryRate: 1,
        lines: lines,
      );
      expect(result.totalFullBoxes, 27);
      expect(result.totalLooseItems, 22);
      expect(result.deliveryFeeTotal, 27);
    });
  });
}
