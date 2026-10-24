class CalculationValidationError {
  const CalculationValidationError({
    required this.code,
    required this.message,
    this.materialId,
  });

  final String code;
  final String message;
  final String? materialId;

  @override
  String toString() {
    return materialId == null ? message : '$message ($materialId)';
  }
}

class CalculationException implements Exception {
  const CalculationException(this.errors);

  final List<CalculationValidationError> errors;

  @override
  String toString() => errors.map((error) => error.message).join('\n');
}
