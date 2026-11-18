import 'package:namma_project/app/l10n/adhkar_strings_adapter.dart';

import '../my_adhkar_state.dart';

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
