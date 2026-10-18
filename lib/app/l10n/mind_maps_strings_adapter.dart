import 'package:flutter/widgets.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/features/mind_maps/presentation/mind_maps_strings.dart';

MindMapsStrings resolveMindMapsStrings(BuildContext context) =>
    _AppMindMapsStrings(FoundationLocalizations.of(context));

final class _AppMindMapsStrings implements MindMapsStrings {
  const _AppMindMapsStrings(this._l10n);
  final FoundationLocalizations _l10n;

  @override
  String get title => _l10n.mindMapsTitle;
  @override
  String get create => _l10n.mindMapsCreate;
  @override
  String get search => _l10n.mindMapsSearch;
  @override
  String get emptyLibrary => _l10n.mindMapsEmptyLibrary;
  @override
  String get emptySearch => _l10n.mindMapsEmptySearch;
  @override
  String get mapTitle => _l10n.mindMapTitleLabel;
  @override
  String get mapDescription => _l10n.mindMapDescriptionLabel;
  @override
  String get editTitle => _l10n.mindMapEditTitle;
  @override
  String get editDescription => _l10n.mindMapEditDescription;
  @override
  String get duplicate => _l10n.mindMapDuplicate;
  @override
  String get delete => _l10n.mindMapDelete;
  @override
  String get deleteConfirmation => _l10n.mindMapDeleteConfirmation;
  @override
  String get save => _l10n.mindMapSave;
  @override
  String get cancel => _l10n.mindMapCancel;
  @override
  String get titleRequired => _l10n.mindMapTitleRequired;
  @override
  String get loadFailure => _l10n.mindMapsLoadFailure;
  @override
  String get saveFailure => _l10n.mindMapsSaveFailure;
  @override
  String get accountFailure => _l10n.mindMapsAccountFailure;
  @override
  String get notFound => _l10n.mindMapsNotFound;
  @override
  String get retry => _l10n.mindMapsRetry;
  @override
  String get nodeCount => _l10n.mindMapNodeCount;
  @override
  String get completedCount => _l10n.mindMapCompletedCount;
  @override
  String get centralNode => _l10n.mindMapCentralNode;
  @override
  String get signInRequired => _l10n.mindMapsSignInRequired;
  @override
  String get back => _l10n.mindMapsBack;
}
