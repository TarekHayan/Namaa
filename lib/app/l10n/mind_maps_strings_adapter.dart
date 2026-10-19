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
  @override
  String get editMap => _l10n.mindMapEditMap;
  @override
  String get addNode => _l10n.mindMapAddNode;
  @override
  String get editNode => _l10n.mindMapEditNode;
  @override
  String get nodeTitle => _l10n.mindMapNodeTitle;
  @override
  String get nodeDescription => _l10n.mindMapNodeDescription;
  @override
  String get nodeKind => _l10n.mindMapNodeKind;
  @override
  String get nodePriority => _l10n.mindMapNodePriority;
  @override
  String get nodeStatus => _l10n.mindMapNodeStatus;
  @override
  String get kindCentral => _l10n.mindMapKindCentral;
  @override
  String get kindMainIdea => _l10n.mindMapKindMainIdea;
  @override
  String get kindBranch => _l10n.mindMapKindBranch;
  @override
  String get kindTask => _l10n.mindMapKindTask;
  @override
  String get kindNote => _l10n.mindMapKindNote;
  @override
  String get statusNotStarted => _l10n.mindMapStatusNotStarted;
  @override
  String get statusInProgress => _l10n.mindMapStatusInProgress;
  @override
  String get statusCompleted => _l10n.mindMapStatusCompleted;
  @override
  String get priorityLow => _l10n.mindMapPriorityLow;
  @override
  String get priorityMedium => _l10n.mindMapPriorityMedium;
  @override
  String get priorityHigh => _l10n.mindMapPriorityHigh;
  @override
  String get nodeTitleRequired => _l10n.mindMapNodeTitleRequired;
  @override
  String get deleteNode => _l10n.mindMapDeleteNode;
  @override
  String get deleteNodeConfirmation => _l10n.mindMapDeleteNodeConfirmation;
  @override
  String get parent => _l10n.mindMapParent;
  @override
  String get detach => _l10n.mindMapDetach;
  @override
  String get sideLink => _l10n.mindMapSideLink;
  @override
  String get connect => _l10n.mindMapConnect;
  @override
  String get disconnect => _l10n.mindMapDisconnect;
  @override
  String get moveNode => _l10n.mindMapMoveNode;
  @override
  String get undo => _l10n.mindMapUndo;
  @override
  String get redo => _l10n.mindMapRedo;
  @override
  String get graphError => _l10n.mindMapGraphError;
  @override
  String get noParent => _l10n.mindMapNoParent;
  @override
  String get progress => _l10n.mindMapProgress;
  @override
  String get chooseTask => _l10n.mindMapChooseTask;
  @override
  String get linkTask => _l10n.mindMapLinkTask;
  @override
  String get changeTask => _l10n.mindMapChangeTask;
  @override
  String get unlinkTask => _l10n.mindMapUnlinkTask;
  @override
  String get linkedTask => _l10n.mindMapLinkedTask;
  @override
  String get taskUnavailable => _l10n.mindMapTaskUnavailable;
  @override
  String get completeTask => _l10n.mindMapCompleteTask;
  @override
  String get reopenTask => _l10n.mindMapReopenTask;
  @override
  String get loadingTasks => _l10n.mindMapLoadingTasks;
  @override
  String get retryTasks => _l10n.mindMapRetryTasks;
  @override
  String get noTasks => _l10n.mindMapNoTasks;
  @override
  String get taskLinkFailure => _l10n.mindMapTaskLinkFailure;
}
