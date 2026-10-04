/// Shared Foundation theme definitions.
library;

import 'package:flutter/material.dart';

/// The Thmanyah Sans family is the default UI typeface for every app theme.
const String kProjectFontFamily = 'ThmanyahSans';

/// The application root owns the three approved appearance modes; this class
/// supplies only the shared light and dark ThemeData definitions.
abstract final class AppTheme {
  static ThemeData get light => ThemeData(
    brightness: Brightness.light,
    fontFamily: kProjectFontFamily,
  );

  static ThemeData get dark => ThemeData(
    brightness: Brightness.dark,
    fontFamily: kProjectFontFamily,
  );
}
