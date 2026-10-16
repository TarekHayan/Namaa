import 'package:flutter/widgets.dart';

abstract interface class HabitsStrings {
  String get title;
  String get empty;
  String get create;
  String get nameLabel;
  String get nameRequired;
  String get weekdaysRequired;
  String get save;
  String get cancel;
  String get complete;
  String get undo;
  String get dueToday;
  String get notDueToday;
  String get loadFailure;
  String get saveFailure;
  String get signInRequired;
  String weekday(int weekday);
}

typedef HabitsStringsResolver = HabitsStrings Function(BuildContext context);
