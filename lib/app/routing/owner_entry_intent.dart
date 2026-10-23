/// Fixed app-owned owner entry requests. No account or business payload travels
/// through route extras; the route gate still resolves the current owner.
library;

import 'package:flutter/widgets.dart';
import 'package:namma_project/core/application/navigation/owner_entry_intent.dart';

export 'package:namma_project/core/application/navigation/owner_entry_intent.dart';

final class OwnerEntryIntentScope extends InheritedWidget {
  const OwnerEntryIntentScope({
    super.key,
    required this.intent,
    required super.child,
  });

  final OwnerEntryIntent? intent;

  static OwnerEntryIntent? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<OwnerEntryIntentScope>()
      ?.intent;

  @override
  bool updateShouldNotify(OwnerEntryIntentScope oldWidget) =>
      intent != oldWidget.intent;
}
