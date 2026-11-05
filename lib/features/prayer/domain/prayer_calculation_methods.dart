/// Calculation-method keys the user may choose. The calculator adapter and
/// the city editor both read this list, so the presentation layer never
/// depends on the data-layer calculator just to render the choices.
const Set<String> kPrayerCalculationMethods = <String>{
  'egyptian',
  'muslimWorldLeague',
  'ummAlQura',
  'dubai',
  'northAmerica',
  'kuwait',
  'qatar',
};
