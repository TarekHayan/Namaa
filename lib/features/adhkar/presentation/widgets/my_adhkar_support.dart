import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart' show Bidi;
import 'package:namma_project/app/l10n/adhkar_strings_adapter.dart';

import '../my_adhkar_state.dart';

/// The width from which the My Adhkar forms open as a dialog (desktop and
/// wide windows) instead of a bottom sheet (phones).
const double kMyAdhkarDialogBreakpoint = 720;

/// The readable width the My Adhkar column is capped at on wide windows.
const double kMyAdhkarMaxContentWidth = 720;

/// The text direction of user content, taken from the text itself (the first
/// strong character), so mixed Arabic and Latin text and a link keep a
/// readable direction. Text with no strong character keeps [fallback].
TextDirection myAdhkarTextDirection(String text, TextDirection fallback) {
  if (Bidi.startsWithRtl(text)) return TextDirection.rtl;
  if (Bidi.startsWithLtr(text)) return TextDirection.ltr;
  return fallback;
}

/// The code points of [text] after trimming, the unit every limit counts in.
int myAdhkarLength(String text) => text.trim().runes.length;

/// The localized message of a typed My Adhkar failure.
String myAdhkarFailureText(AdhkarStrings copy, MyAdhkarFailure failure) =>
    switch (failure) {
      MyAdhkarFailure.groupNameInvalid => copy.myAdhkarGroupNameInvalid,
      MyAdhkarFailure.textInvalid => copy.myAdhkarTextInvalid,
      MyAdhkarFailure.sourceInvalid => copy.myAdhkarSourceInvalid,
      MyAdhkarFailure.groupSetInvalid => copy.myAdhkarGroupSetInvalid,
      MyAdhkarFailure.groupLimitReached => copy.myAdhkarCreateGroupDisabled,
      MyAdhkarFailure.entryLimitReached => copy.myAdhkarAddDisabled,
      MyAdhkarFailure.groupDeleted => copy.myAdhkarGroupDeleted,
      MyAdhkarFailure.groupUnknown => copy.myAdhkarGroupUnknown,
      MyAdhkarFailure.itemDeleted => copy.myAdhkarItemDeleted,
      MyAdhkarFailure.itemUnknown => copy.myAdhkarItemUnknown,
      MyAdhkarFailure.unavailable => copy.myAdhkarSaveFailed,
    };
