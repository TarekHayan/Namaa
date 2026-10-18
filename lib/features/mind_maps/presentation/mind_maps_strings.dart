import 'package:flutter/widgets.dart';

abstract interface class MindMapsStrings {
  String get title;
  String get create;
  String get search;
  String get emptyLibrary;
  String get emptySearch;
  String get mapTitle;
  String get mapDescription;
  String get editTitle;
  String get editDescription;
  String get duplicate;
  String get delete;
  String get deleteConfirmation;
  String get save;
  String get cancel;
  String get titleRequired;
  String get loadFailure;
  String get saveFailure;
  String get accountFailure;
  String get notFound;
  String get retry;
  String get nodeCount;
  String get completedCount;
  String get centralNode;
  String get signInRequired;
  String get back;
}

typedef MindMapsStringsResolver =
    MindMapsStrings Function(BuildContext context);
