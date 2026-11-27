/// Unknown, invalid and negative nutrient values are not measured zeros.
double? knownNutrient(Object? value) {
  if (value is! num || !value.isFinite || value < 0) return null;
  return value.toDouble();
}

double requiredEnergy(Object? value) {
  final energy = knownNutrient(value);
  if (energy == null) {
    throw const FormatException('A measured calorie value is required');
  }
  return energy;
}

/// Returns unknown if any contributing record is incomplete. Empty input means
/// no logged quantity, not a claim about what the person actually consumed.
double? sumKnownNutrients(Iterable<double?> values) {
  var sum = 0.0;
  for (final value in values) {
    if (value == null || !value.isFinite || value < 0) return null;
    sum += value;
  }
  return sum;
}
