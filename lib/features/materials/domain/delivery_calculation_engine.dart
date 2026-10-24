import '../../../core/constants/business_ids.dart';

class DeliveryLineData {
  const DeliveryLineData({
    required this.packagingFullBoxes,
    required this.packagingLooseItems,
  });

  final int packagingFullBoxes;
  final int packagingLooseItems;
}

class DeliveryCalculationResult {
  const DeliveryCalculationResult({
    required this.deliveryModeId,
    required this.deliveryPayerId,
    required this.deliveryRate,
    required this.totalFullBoxes,
    required this.totalLooseItems,
    required this.deliveryFeeTotal,
  });

  final String deliveryModeId;
  final String deliveryPayerId;
  final double deliveryRate;
  final int totalFullBoxes;
  final int totalLooseItems;
  final double deliveryFeeTotal;
}

DeliveryCalculationResult calculateDelivery({
  required String deliveryModeId,
  required String deliveryPayerId,
  required double deliveryRate,
  required List<DeliveryLineData> lines,
}) {
  var totalFullBoxes = 0;
  var totalLooseItems = 0;

  for (final line in lines) {
    totalFullBoxes += line.packagingFullBoxes;
    totalLooseItems += line.packagingLooseItems;
  }

  double deliveryFeeTotal = 0;

  switch (deliveryModeId) {
    case DeliveryModeIds.flatDelivery:
      deliveryFeeTotal = deliveryRate;
      break;
    case DeliveryModeIds.perBoxDelivery:
      deliveryFeeTotal = totalFullBoxes * deliveryRate;
      break;
    default:
      deliveryFeeTotal = deliveryRate;
      break;
  }

  return DeliveryCalculationResult(
    deliveryModeId: deliveryModeId,
    deliveryPayerId: deliveryPayerId,
    deliveryRate: deliveryRate,
    totalFullBoxes: totalFullBoxes,
    totalLooseItems: totalLooseItems,
    deliveryFeeTotal: deliveryFeeTotal,
  );
}
