typedef QuantityRounder = int Function(double value);

class QuantityRounding {
  const QuantityRounding._();

  static int customerCeil(double value) {
    if (value <= 0) {
      return 0;
    }
    return value.ceil();
  }
}

/// Rounds a non-negative Ceiling material quantity to the nearest integer,
/// with exact half values rounded up.
///
/// Raw formula results are normalized to nine decimal places first so normal
/// floating-point noise around a mathematical half cannot flip the result.
int roundCeilingQuantity(double value) {
  if (!value.isFinite) {
    throw ArgumentError.value(value, 'value', 'must be finite');
  }
  if (value <= 0) {
    return 0;
  }

  const precisionFactor = 1000000000.0;
  final normalized =
      (value * precisionFactor).roundToDouble() / precisionFactor;
  return (normalized + 0.5).floor();
}
