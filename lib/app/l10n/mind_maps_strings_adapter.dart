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
  @override
  String get settings => _l10n.mindMapSettings;
  @override
  String get layout => _l10n.mindMapLayout;
  @override
  String get applyLayout => _l10n.mindMapApplyLayout;
  @override
  String get layoutRadial => _l10n.mindMapLayoutRadial;
  @override
  String get layoutTree => _l10n.mindMapLayoutTree;
  @override
  String get layoutHorizontal => _l10n.mindMapLayoutHorizontal;
  @override
  String get layoutVertical => _l10n.mindMapLayoutVertical;
  @override
  String get layoutFreeform => _l10n.mindMapLayoutFreeform;
  @override
  String get background => _l10n.mindMapBackground;
  @override
  String get defaultNode => _l10n.mindMapDefaultNode;
  @override
  String get connectionStyle => _l10n.mindMapConnectionStyle;
  @override
  String get spacing => _l10n.mindMapSpacing;
  @override
  String get nodeColor => _l10n.mindMapNodeColor;
  @override
  String get connectionColor => _l10n.mindMapConnectionColor;
  @override
  String get connectionWidth => _l10n.mindMapConnectionWidth;
  @override
  String get nodeIcon => _l10n.mindMapNodeIcon;
  @override
  String get nodeShape => _l10n.mindMapNodeShape;
  @override
  String get nodeSize => _l10n.mindMapNodeSize;
  @override
  String get textSize => _l10n.mindMapTextSize;
  @override
  String get shapeRectangle => _l10n.mindMapShapeRectangle;
  @override
  String get shapeRounded => _l10n.mindMapShapeRounded;
  @override
  String get shapeCircle => _l10n.mindMapShapeCircle;
  @override
  String get shapePill => _l10n.mindMapShapePill;
  @override
  String get shapeGlass => _l10n.mindMapShapeGlass;
  @override
  String get sizeSmall => _l10n.mindMapSizeSmall;
  @override
  String get sizeMedium => _l10n.mindMapSizeMedium;
  @override
  String get sizeLarge => _l10n.mindMapSizeLarge;
  @override
  String get iconIdea => _l10n.mindMapIconIdea;
  @override
  String get iconTask => _l10n.mindMapIconTask;
  @override
  String get iconNote => _l10n.mindMapIconNote;
  @override
  String get iconStar => _l10n.mindMapIconStar;
  @override
  String get iconFlag => _l10n.mindMapIconFlag;
  @override
  String get colorWhite => _l10n.mindMapColorWhite;
  @override
  String get colorBlue => _l10n.mindMapColorBlue;
  @override
  String get colorGreen => _l10n.mindMapColorGreen;
  @override
  String get colorAmber => _l10n.mindMapColorAmber;
  @override
  String get colorPurple => _l10n.mindMapColorPurple;
  @override
  String get colorDark => _l10n.mindMapColorDark;
  @override
  String get colorCurrent => _l10n.mindMapColorCurrent;
  @override
  String get fit => _l10n.mindMapFit;
  @override
  String get center => _l10n.mindMapCenter;
  @override
  String get zoomIn => _l10n.mindMapZoomIn;
  @override
  String get zoomOut => _l10n.mindMapZoomOut;
  @override
  String get panLeft => _l10n.mindMapPanLeft;
  @override
  String get panRight => _l10n.mindMapPanRight;
  @override
  String get panUp => _l10n.mindMapPanUp;
  @override
  String get panDown => _l10n.mindMapPanDown;
  @override
  String get dragNode => _l10n.mindMapDragNode;
  @override
  String get keyboardHelp => _l10n.mindMapKeyboardHelp;
}
