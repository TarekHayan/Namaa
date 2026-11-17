import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:namma_project/app/l10n/adhkar_strings_adapter.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/features/adhkar/domain/my_dhikr.dart';

import '../my_adhkar_cubit.dart';
import '../my_adhkar_state.dart';
import 'my_adhkar_support.dart';

/// Opens a My Adhkar form as a bottom sheet on phones and as a dialog on
/// wide windows (contracts/adhkar-qiyam-ui.md). The [builder] is built under
/// the route's own context, so it must not rely on the tab's providers: the
/// forms take the Cubit explicitly.
Future<void> showMyAdhkarForm(BuildContext context, WidgetBuilder builder) {
  if (MediaQuery.sizeOf(context).width >= kMyAdhkarDialogBreakpoint) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: builder(dialogContext),
        ),
      ),
    );
  }
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: builder,
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
    final theme = Theme.of(context);
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
      builder: (context, state) => SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16,
          8,
          16,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          key: const Key('my_adhkar_group_form'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.existing == null
                  ? copy.myAdhkarGroupSheetTitleCreate
                  : copy.myAdhkarGroupSheetTitleRename,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('my_adhkar_group_name_field'),
              controller: _name,
              autofocus: true,
              textDirection: myAdhkarTextDirection(_name.text, ambient),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                if (_valid && !state.busy) _save();
              },
              decoration: InputDecoration(
                labelText: copy.myAdhkarGroupNameLabel,
                errorText: error,
                errorMaxLines: 3,
                counter: Text(
                  copy.counter(length, MyAdhkarGroupDraft.maxNameLength),
                  key: const Key('my_adhkar_group_name_counter'),
                  style: tooLong
                      ? TextStyle(color: theme.colorScheme.error)
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 16),
            OverflowBar(
              alignment: MainAxisAlignment.end,
              spacing: 8,
              overflowSpacing: 8,
              children: [
                TextButton(
                  key: const Key('my_adhkar_group_cancel'),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(copy.myAdhkarCancel),
                ),
                FilledButton(
                  key: const Key('my_adhkar_group_save'),
                  onPressed: _valid && !state.busy ? _save : null,
                  child: Text(copy.myAdhkarSave),
                ),
              ],
            ),
          ],
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
    final theme = Theme.of(context);
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
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            16,
            8,
            16,
            16 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            key: const Key('my_adhkar_entry_form'),
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.existing == null
                    ? copy.myAdhkarEntrySheetTitleAdd
                    : copy.myAdhkarEntrySheetTitleEdit,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('my_adhkar_text_field'),
                controller: _text,
                autofocus: true,
                minLines: 3,
                maxLines: 8,
                keyboardType: TextInputType.multiline,
                textDirection: myAdhkarTextDirection(_text.text, ambient),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontFamily: 'Amiri',
                  height: 1.7,
                ),
                decoration: InputDecoration(
                  labelText: copy.myAdhkarTextLabel,
                  hintText: copy.myAdhkarTextHint,
                  errorText: textError,
                  errorMaxLines: 3,
                  alignLabelWithHint: true,
                  counter: Text(
                    copy.counter(textLength, MyDhikrDraft.maxTextLength),
                    key: const Key('my_adhkar_text_counter'),
                    style: textTooLong
                        ? TextStyle(color: theme.colorScheme.error)
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('my_adhkar_source_field'),
                controller: _source,
                minLines: 1,
                maxLines: 3,
                keyboardType: TextInputType.multiline,
                textDirection: myAdhkarTextDirection(_source.text, ambient),
                decoration: InputDecoration(
                  labelText: copy.myAdhkarSourceLabel,
                  hintText: copy.myAdhkarSourceHint,
                  errorText: sourceError,
                  errorMaxLines: 3,
                  counter: Text(
                    copy.counter(sourceLength, MyDhikrDraft.maxSourceLength),
                    key: const Key('my_adhkar_source_counter'),
                    style: sourceTooLong
                        ? TextStyle(color: theme.colorScheme.error)
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(copy.myAdhkarGroupsLabel, style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final summary in state.groups)
                    FilterChip(
                      key: Key('my_adhkar_group_chip_${summary.group.groupId}'),
                      selected: liveSelected.contains(summary.group.groupId),
                      label: Text(
                        summary.group.name,
                        textDirection: myAdhkarTextDirection(
                          summary.group.name,
                          ambient,
                        ),
                      ),
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
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    copy.myAdhkarGroupSetInvalid,
                    key: const Key('my_adhkar_group_set_error'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              if (_failure != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    myAdhkarFailureText(copy, _failure!),
                    key: const Key('my_adhkar_form_error'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              OverflowBar(
                alignment: MainAxisAlignment.end,
                spacing: 8,
                overflowSpacing: 8,
                children: [
                  TextButton(
                    key: const Key('my_adhkar_entry_cancel'),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(copy.myAdhkarCancel),
                  ),
                  FilledButton(
                    key: const Key('my_adhkar_entry_save'),
                    onPressed: canSave ? () => _save(liveSelected) : null,
                    child: Text(copy.myAdhkarSave),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
