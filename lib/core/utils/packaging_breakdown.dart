class PackagingBreakdown {
  const PackagingBreakdown({
    required this.totalQuantity,
    required this.itemsPerBox,
    required this.fullBoxes,
    required this.looseItems,
  });

  final int totalQuantity;
  final int itemsPerBox;
  final int fullBoxes;
  final int looseItems;
}

PackagingBreakdown breakdownFromTotalQuantity({
  required int totalQuantity,
  required int itemsPerBox,
}) {
  if (itemsPerBox <= 0) {
    return PackagingBreakdown(
      totalQuantity: totalQuantity,
      itemsPerBox: 0,
      fullBoxes: 0,
      looseItems: totalQuantity,
    );
  }

  return PackagingBreakdown(
    totalQuantity: totalQuantity,
    itemsPerBox: itemsPerBox,
    fullBoxes: totalQuantity ~/ itemsPerBox,
    looseItems: totalQuantity % itemsPerBox,
  );
}

PackagingBreakdown breakdownFromBoxQuantity({
  required int boxQuantity,
  required int itemsPerBox,
}) {
  return PackagingBreakdown(
    totalQuantity: boxQuantity * itemsPerBox,
    itemsPerBox: itemsPerBox,
    fullBoxes: boxQuantity,
    looseItems: 0,
  );
}

PackagingBreakdown breakdownFromBoxPlusLoose({
  required int boxQuantity,
  required int looseQuantity,
  required int itemsPerBox,
}) {
  return PackagingBreakdown(
    totalQuantity: boxQuantity * itemsPerBox + looseQuantity,
    itemsPerBox: itemsPerBox,
    fullBoxes: boxQuantity,
    looseItems: looseQuantity,
  );
}
