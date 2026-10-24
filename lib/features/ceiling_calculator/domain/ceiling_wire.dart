/// Wire packs required by the combined ceiling area.
class CeilingWire {
  const CeilingWire(this.lengthM, this.price);

  final int lengthM;
  final double price;

  factory CeilingWire.forArea(double areaM2) {
    if (!areaM2.isFinite || areaM2 <= 0) return const CeilingWire(0, 0);
    final hundreds = (areaM2 / 100).floor();
    final remainder = areaM2 - hundreds * 100;
    final (length, price) = switch (remainder) {
      <= 0 => (0, 0),
      <= 25 => (250, 5),
      <= 50 => (500, 10),
      _ => (1000, 15),
    };
    return CeilingWire(hundreds * 1000 + length, hundreds * 15.0 + price);
  }
}
