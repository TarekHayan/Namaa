import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:namma_project/app/l10n/adhkar_strings_adapter.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/app/theme/app_colors.dart';
import 'package:namma_project/app/theme/app_typography.dart';
import 'package:namma_project/app/widgets/app_button.dart';
import 'package:namma_project/app/widgets/app_confirmation.dart';
import 'package:namma_project/app/widgets/app_filter_chip.dart';
import 'package:namma_project/app/widgets/app_form_field.dart';
import 'package:namma_project/app/widgets/app_notice.dart';
import 'package:namma_project/app/widgets/app_sheets.dart';
import 'package:namma_project/features/adhkar/domain/my_dhikr.dart';

import '../my_adhkar_cubit.dart';
import '../my_adhkar_state.dart';
import 'adhkar_style.dart';
import 'my_adhkar_support.dart';

/// Opens a My Adhkar form as a bottom sheet on phones and as a dialog on
/// wide windows (contracts/adhkar-qiyam-ui.md). The [builder] is built under
/// the route's own context, so it must not rely on the tab's providers: the
/// forms take the Cubit explicitly.
Future<void> showMyAdhkarForm(BuildContext context, WidgetBuilder builder) =>
    showAppAdaptiveSheet<void>(context, builder);

/// Save and Cancel side by side (stacked when narrow), Save first.
final class _FormFooter extends StatelessWidget {
  const _FormFooter({
    required this.saveKey,
    required this.cancelKey,
    required this.saveLabel,
    required this.cancelLabel,
    required this.onSave,
    required this.onCancel,
  });

  final Key saveKey;
  final Key cancelKey;
  final String saveLabel;
  final String cancelLabel;
  final VoidCallback? onSave;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) => AppButtonPair(
    minInlineWidth: 290,
    primary: AppButton(
      key: saveKey,
      label: saveLabel,
      onPressed: onSave,
      look: AppButtonLook.refined,
    ),
    secondary: AppButton(
      key: cancelKey,
      label: cancelLabel,
      onPressed: onCancel,
      look: AppButtonLook.refined,
      variant: AppButtonVariant.secondary,
    ),
  );
}

/// The create / rename group form: the name field with its 60-character
/// counter. Save is disabled until the trimmed name is 1–60 characters;
/// a rejected command shows its typed reason inline.
final class MyAdhkarGroupForm extends StatefulWidget {
  const MyAdhkarGroupForm({super.key, required this.cubit, this.existing});

  final MyAdhkarCubit cubit;

  /// The group being renamed; null creates a new one.
  final MyAdhkarGroup? existing;

  @override
  State<MyAdhkarGroupForm> createState() => _MyAdhkarGroupFormState();
}

final class _MyAdhkarGroupFormState extends State<MyAdhkarGroupForm> {
  late final TextEditingController _name;
  late String _lastName;
  MyAdhkarFailure? _failure;
  bool _touched = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.name ?? '');
    _lastName = _name.text;
    _name.addListener(_changed);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _changed() {
    // A caret move or focus change also notifies; only an edit counts.
    if (_name.text == _lastName) return;
    _lastName = _name.text;
    setState(() {
      _failure = null;
      _touched = true;
    });
  }

  bool get _valid {
    final length = myAdhkarLength(_name.text);
    return length >= MyAdhkarGroupDraft.minNameLength &&
        length <= MyAdhkarGroupDraft.maxNameLength;
  }

  Future<void> _save() async {
    final existing = widget.existing;
    final result = existing == null
        ? await widget.cubit.createGroup(name: _name.text)
        : await widget.cubit.renameGroup(
            groupId: existing.groupId,
            name: _name.text,
          );
    if (!mounted || result.ignored) return;
    if (result.succeeded) {
      Navigator.of(context).pop();
    } else {
      setState(() => _failure = result.failure);
    }
  }

  @override
  Widget build(BuildContext context) {
    final copy = AdhkarStrings(FoundationLocalizations.of(context));
    final colors = AppColors.of(context);
    final length = myAdhkarLength(_name.text);
    final tooLong = length > MyAdhkarGroupDraft.maxNameLength;
    final ambient = Directionality.of(context);
    final String? error = _failure != null
        ? myAdhkarFailureText(copy, _failure!)
        : (tooLong || (_touched && length == 0))
        ? copy.myAdhkarGroupNameInvalid
        : null;
    return BlocBuilder<MyAdhkarCubit, MyAdhkarState>(
      bloc: widget.cubit,
      builder: (context, state) => AppFormSheet(
        panelKey: const Key('my_adhkar_group_form'),
        title: widget.existing == null
            ? copy.myAdhkarGroupSheetTitleCreate
            : copy.myAdhkarGroupSheetTitleRename,
        fields: [
          AppLabeledField(
            label: copy.myAdhkarGroupNameLabel,
            field: TextField(
              key: const Key('my_adhkar_group_name_field'),
              controller: _name,
              autofocus: true,
              textDirection: AppTypography.directionFor(_name.text, ambient),
              textInputAction: TextInputAction.done,
              style: AppTypography.fixed(
                16,
                FontWeight.w400,
                colors.textPrimary,
              ),
              onSubmitted: (_) {
                if (_valid && !state.busy) _save();
              },
              decoration: appCountedFieldDecoration(
                colors,
                counterText: copy.counter(
                  length,
                  MyAdhkarGroupDraft.maxNameLength,
                ),
                counterKey: const Key('my_adhkar_group_name_counter'),
                counterError: tooLong,
                errorText: error,
              ),
            ),
          ),
        ],
        footer: _FormFooter(
          saveKey: const Key('my_adhkar_group_save'),
          cancelKey: const Key('my_adhkar_group_cancel'),
          saveLabel: copy.myAdhkarSave,
          cancelLabel: copy.myAdhkarCancel,
          onSave: _valid && !state.busy ? _save : null,
          onCancel: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }
}

/// The add / edit entry form: the text (multi-line, counter to 2000), the
/// optional source (counter to 500, hint "a book, a scholar or a link"), and
/// the group choice (chips of the live groups, multi-select). Save is
/// disabled until the text is valid and at least one group is selected.
/// Lengths count Unicode code points (so Arabic diacritics count), which is
/// why the fields carry no `maxLength` of their own: the counter turns red
/// and an inline error explains an over-long value instead.
final class MyAdhkarEntryForm extends StatefulWidget {
  const MyAdhkarEntryForm({
    super.key,
    required this.cubit,
    required this.openedGroupId,
    this.existing,
  });

  final MyAdhkarCubit cubit;

  /// The group the form was opened from; preselected when adding.
  final String openedGroupId;

  /// The entry being edited; null adds a new one.
  final MyDhikrItem? existing;

  @override
  State<MyAdhkarEntryForm> createState() => _MyAdhkarEntryFormState();
}

final class _MyAdhkarEntryFormState extends State<MyAdhkarEntryForm> {
  late final TextEditingController _text;
  late final TextEditingController _source;
  late final Set<String> _selected;
  late String _lastText;
  late String _lastSource;
  MyAdhkarFailure? _failure;
  bool _textTouched = false;

  @override
  void initState() {
    super.initState();
    _text = TextEditingController(text: widget.existing?.text ?? '');
    _source = TextEditingController(text: widget.existing?.source ?? '');
    _lastText = _text.text;
    _lastSource = _source.text;
    _text.addListener(_changed);
    _source.addListener(_changed);
    _selected = {
      if (widget.existing != null)
        ...widget.existing!.groupIds
      else
        widget.openedGroupId,
    };
  }

  @override
  void dispose() {
    _text.dispose();
    _source.dispose();
    super.dispose();
  }

  void _changed() {
    // A caret move or focus change also notifies; only an edit counts.
    if (_text.text == _lastText && _source.text == _lastSource) return;
    setState(() {
      _failure = null;
      if (_text.text != _lastText) _textTouched = true;
      _lastText = _text.text;
      _lastSource = _source.text;
    });
  }

  bool get _textValid {
    final length = myAdhkarLength(_text.text);
    return length >= MyDhikrDraft.minTextLength &&
        length <= MyDhikrDraft.maxTextLength;
  }

  bool get _sourceValid =>
      myAdhkarLength(_source.text) <= MyDhikrDraft.maxSourceLength;

  Future<void> _save(Set<String> liveSelected) async {
    final draft = MyDhikrDraft(
      text: _text.text,
      source: _source.text,
      groupIds: liveSelected.toList(),
    );
    final existing = widget.existing;
    final result = existing == null
        ? await widget.cubit.addEntry(draft: draft)
        : await widget.cubit.editEntry(itemId: existing.itemId, draft: draft);
    if (!mounted || result.ignored) return;
    if (result.succeeded) {
      Navigator.of(context).pop();
    } else {
      setState(() => _failure = result.failure);
    }
  }

  @override
  Widget build(BuildContext context) {
    final copy = AdhkarStrings(FoundationLocalizations.of(context));
    final colors = AppColors.of(context);
    final ambient = Directionality.of(context);
    final textLength = myAdhkarLength(_text.text);
    final sourceLength = myAdhkarLength(_source.text);
    final textTooLong = textLength > MyDhikrDraft.maxTextLength;
    final sourceTooLong = sourceLength > MyDhikrDraft.maxSourceLength;
    return BlocBuilder<MyAdhkarCubit, MyAdhkarState>(
      bloc: widget.cubit,
      builder: (context, state) {
        // Only live groups can be chosen; a group deleted meanwhile drops
        // out of the selection.
        final liveIds = {for (final s in state.groups) s.group.groupId};
        final liveSelected = _selected.intersection(liveIds);
        final String? textError = (textTooLong || (_textTouched && !_textValid))
            ? copy.myAdhkarTextInvalid
            : null;
        final String? sourceError = sourceTooLong
            ? copy.myAdhkarSourceInvalid
            : null;
        final canSave =
            _textValid &&
            _sourceValid &&
            liveSelected.isNotEmpty &&
            !state.busy;
        return AppFormSheet(
          panelKey: const Key('my_adhkar_entry_form'),
          title: widget.existing == null
              ? copy.myAdhkarEntrySheetTitleAdd
              : copy.myAdhkarEntrySheetTitleEdit,
          fields: [
            AppLabeledField(
              label: copy.myAdhkarTextLabel,
              field: TextField(
                key: const Key('my_adhkar_text_field'),
                controller: _text,
                autofocus: true,
                minLines: 4,
                maxLines: 8,
                keyboardType: TextInputType.multiline,
                textDirection: AppTypography.directionFor(_text.text, ambient),
                style: AppTypography.fixed(
                  22,
                  FontWeight.w400,
                  colors.textPrimary,
                  height: 1.9,
                ).copyWith(fontFamily: kDhikrFontFamily),
                decoration: appCountedFieldDecoration(
                  colors,
                  counterText: copy.counter(
                    textLength,
                    MyDhikrDraft.maxTextLength,
                  ),
                  counterKey: const Key('my_adhkar_text_counter'),
                  counterError: textTooLong,
                  errorText: textError,
                ),
              ),
            ),
            AppLabeledField(
              label: copy.myAdhkarSourceLabel,
              field: TextField(
                key: const Key('my_adhkar_source_field'),
                controller: _source,
                minLines: 1,
                maxLines: 3,
                keyboardType: TextInputType.multiline,
                textDirection: AppTypography.directionFor(
                  _source.text,
                  ambient,
                ),
                style: AppTypography.fixed(
                  16,
                  FontWeight.w400,
                  colors.textPrimary,
                ),
                decoration: appCountedFieldDecoration(
                  colors,
                  counterText: copy.counter(
                    sourceLength,
                    MyDhikrDraft.maxSourceLength,
                  ),
                  counterKey: const Key('my_adhkar_source_counter'),
                  counterError: sourceTooLong,
                  errorText: sourceError,
                  helperText: copy.myAdhkarSourceHint,
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  copy.myAdhkarGroupsLabel,
                  style: AppTypography.fixed(
                    14,
                    FontWeight.w700,
                    colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final summary in state.groups)
                      AppFilterChip(
                        key: Key(
                          'my_adhkar_group_chip_${summary.group.groupId}',
                        ),
                        label: summary.group.name,
                        textDirection: AppTypography.directionFor(
                          summary.group.name,
                          ambient,
                        ),
                        selected: liveSelected.contains(summary.group.groupId),
                        onSelected: (on) => setState(() {
                          _failure = null;
                          if (on) {
                            _selected.add(summary.group.groupId);
                          } else {
                            _selected.remove(summary.group.groupId);
                          }
                        }),
                      ),
                  ],
                ),
                if (liveSelected.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: AppInlineNote(
                      key: const Key('my_adhkar_group_set_error'),
                      text: copy.myAdhkarGroupSetInvalid,
                      tone: AppNoticeTone.error,
                    ),
                  ),
                if (_failure != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: AppInlineNote(
                      key: const Key('my_adhkar_form_error'),
                      text: myAdhkarFailureText(copy, _failure!),
                      tone: AppNoticeTone.error,
                    ),
                  ),
              ],
            ),
          ],
          footer: _FormFooter(
            saveKey: const Key('my_adhkar_entry_save'),
            cancelKey: const Key('my_adhkar_entry_cancel'),
            saveLabel: copy.myAdhkarSave,
            cancelLabel: copy.myAdhkarCancel,
            onSave: canSave ? () => _save(liveSelected) : null,
            onCancel: () => Navigator.of(context).pop(),
          ),
        );
      },
    );
  }
}
