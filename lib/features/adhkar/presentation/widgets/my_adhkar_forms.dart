import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:namma_project/app/l10n/adhkar_strings_adapter.dart';
import 'package:namma_project/app/l10n/generated/app_localizations.dart';
import 'package:namma_project/features/adhkar/domain/my_dhikr.dart';

import '../my_adhkar_cubit.dart';
import '../my_adhkar_state.dart';
import 'adhkar_controls.dart';
import 'adhkar_style.dart';
import 'my_adhkar_support.dart';

/// Opens a My Adhkar form as a bottom sheet on phones and as a dialog on
/// wide windows (contracts/adhkar-qiyam-ui.md). The [builder] is built under
/// the route's own context, so it must not rely on the tab's providers: the
/// forms take the Cubit explicitly.
Future<void> showMyAdhkarForm(BuildContext context, WidgetBuilder builder) {
  final palette = AdhkarPalette.of(context);
  if (MediaQuery.sizeOf(context).width >= kMyAdhkarDialogBreakpoint) {
    return showDialog<void>(
      context: context,
      barrierColor: palette.scrim,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.all(40),
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
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: palette.scrim,
    builder: builder,
  );
}

/// The shared panel of the group and entry forms: a bottom sheet (with its
/// drag handle) on a phone and a dialog card on a wide window, the title, a
/// scrolling body, and the Save / Cancel footer.
final class _FormPanel extends StatelessWidget {
  const _FormPanel({
    required this.panelKey,
    required this.title,
    required this.body,
    required this.footer,
  });

  final Key panelKey;
  final String title;
  final List<Widget> body;
  final Widget footer;

  @override
  Widget build(BuildContext context) {
    final palette = AdhkarPalette.of(context);
    final phone = MediaQuery.sizeOf(context).width < kMyAdhkarDialogBreakpoint;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        key: panelKey,
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: phone
              ? const BorderRadius.vertical(top: Radius.circular(28))
              : BorderRadius.circular(28),
          border: Border.all(color: palette.border),
          boxShadow: palette.glow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (phone)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: palette.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 8),
              child: Text(
                title,
                style: adhkarText(
                  20,
                  FontWeight.w700,
                  palette.text,
                  height: 1.45,
                ),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < body.length; i++) ...[
                      if (i > 0) const SizedBox(height: 18),
                      body[i],
                    ],
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: palette.border)),
              ),
              child: footer,
            ),
          ],
        ),
      ),
    );
  }
}

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
  Widget build(BuildContext context) {
    final palette = AdhkarPalette.of(context);
    final save = AdhkarGlow(
      enabled: onSave != null,
      child: FilledButton(
        key: saveKey,
        style: adhkarPrimaryStyle(palette),
        onPressed: onSave,
        child: Text(saveLabel),
      ),
    );
    final cancel = FilledButton(
      key: cancelKey,
      style: adhkarSecondaryStyle(palette),
      onPressed: onCancel,
      child: Text(cancelLabel),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 290) {
          return Row(
            children: [
              Expanded(child: save),
              const SizedBox(width: 10),
              Expanded(child: cancel),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [save, const SizedBox(height: 10), cancel],
        );
      },
    );
  }
}

/// A field with its label above it, as the design lays forms out.
final class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.field});

  final String label;
  final Widget field;

  @override
  Widget build(BuildContext context) {
    final palette = AdhkarPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: adhkarText(14, FontWeight.w700, palette.text)),
        const SizedBox(height: 8),
        field,
      ],
    );
  }
}

/// The design's input: a filled field with a 16 px radius, a hairline border
/// that becomes a 1.5 px accent border while focused and a 1.5 px error
/// border when invalid, the error with its icon on the start side and the
/// counter (always left to right) on the end side.
InputDecoration _fieldDecoration(
  AdhkarPalette palette, {
  required String counterText,
  required Key counterKey,
  required bool counterError,
  String? errorText,
  String? helperText,
}) {
  OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: BorderSide(color: color, width: width),
  );
  return InputDecoration(
    filled: true,
    fillColor: palette.surface2,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: border(palette.border, 1),
    enabledBorder: border(palette.border, 1),
    focusedBorder: border(palette.primary, 1.5),
    errorBorder: border(palette.error, 1.5),
    focusedErrorBorder: border(palette.error, 1.5),
    error: errorText == null
        ? null
        : AdhkarNote(
            text: errorText,
            color: palette.errorText,
            iconColor: palette.errorText,
            weight: FontWeight.w600,
          ),
    helper: helperText == null
        ? null
        : Text(
            helperText,
            style: adhkarText(14, FontWeight.w400, palette.text2, height: 1.6),
          ),
    helperMaxLines: 3,
    counter: Directionality(
      textDirection: TextDirection.ltr,
      child: Text(
        counterText,
        key: counterKey,
        style: adhkarText(
          14,
          FontWeight.w400,
          counterError ? palette.errorText : palette.text2,
        ),
      ),
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
    final palette = AdhkarPalette.of(context);
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
      builder: (context, state) => _FormPanel(
        panelKey: const Key('my_adhkar_group_form'),
        title: widget.existing == null
            ? copy.myAdhkarGroupSheetTitleCreate
            : copy.myAdhkarGroupSheetTitleRename,
        body: [
          _LabeledField(
            label: copy.myAdhkarGroupNameLabel,
            field: TextField(
              key: const Key('my_adhkar_group_name_field'),
              controller: _name,
              autofocus: true,
              textDirection: myAdhkarTextDirection(_name.text, ambient),
              textInputAction: TextInputAction.done,
              style: adhkarText(16, FontWeight.w400, palette.text),
              onSubmitted: (_) {
                if (_valid && !state.busy) _save();
              },
              decoration: _fieldDecoration(
                palette,
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
    final palette = AdhkarPalette.of(context);
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
        return _FormPanel(
          panelKey: const Key('my_adhkar_entry_form'),
          title: widget.existing == null
              ? copy.myAdhkarEntrySheetTitleAdd
              : copy.myAdhkarEntrySheetTitleEdit,
          body: [
            _LabeledField(
              label: copy.myAdhkarTextLabel,
              field: TextField(
                key: const Key('my_adhkar_text_field'),
                controller: _text,
                autofocus: true,
                minLines: 4,
                maxLines: 8,
                keyboardType: TextInputType.multiline,
                textDirection: myAdhkarTextDirection(_text.text, ambient),
                style: adhkarText(
                  22,
                  FontWeight.w400,
                  palette.text,
                  height: 1.9,
                ).copyWith(fontFamily: kDhikrFontFamily),
                decoration: _fieldDecoration(
                  palette,
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
            _LabeledField(
              label: copy.myAdhkarSourceLabel,
              field: TextField(
                key: const Key('my_adhkar_source_field'),
                controller: _source,
                minLines: 1,
                maxLines: 3,
                keyboardType: TextInputType.multiline,
                textDirection: myAdhkarTextDirection(_source.text, ambient),
                style: adhkarText(16, FontWeight.w400, palette.text),
                decoration: _fieldDecoration(
                  palette,
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
                  style: adhkarText(14, FontWeight.w700, palette.text),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final summary in state.groups)
                      _GroupChip(
                        chipKey: Key(
                          'my_adhkar_group_chip_${summary.group.groupId}',
                        ),
                        name: summary.group.name,
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
                    child: AdhkarNote(
                      key: const Key('my_adhkar_group_set_error'),
                      text: copy.myAdhkarGroupSetInvalid,
                      color: palette.errorText,
                      iconColor: palette.errorText,
                      weight: FontWeight.w600,
                    ),
                  ),
                if (_failure != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: AdhkarNote(
                      key: const Key('my_adhkar_form_error'),
                      text: myAdhkarFailureText(copy, _failure!),
                      color: palette.errorText,
                      iconColor: palette.errorText,
                      weight: FontWeight.w600,
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

/// A group choice: a 48 px pill, with the accent border and a check when
/// selected.
final class _GroupChip extends StatelessWidget {
  const _GroupChip({
    required this.chipKey,
    required this.name,
    required this.selected,
    required this.onSelected,
  });

  final Key chipKey;
  final String name;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    final palette = AdhkarPalette.of(context);
    return FilterChip(
      key: chipKey,
      selected: selected,
      onSelected: onSelected,
      showCheckmark: true,
      checkmarkColor: palette.accent,
      backgroundColor: palette.surface2,
      selectedColor: palette.soft,
      surfaceTintColor: Colors.transparent,
      side: BorderSide(color: selected ? palette.primary : palette.border),
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      materialTapTargetSize: MaterialTapTargetSize.padded,
      label: Text(
        name,
        textDirection: myAdhkarTextDirection(name, Directionality.of(context)),
        style: adhkarText(
          14,
          selected ? FontWeight.w700 : FontWeight.w600,
          selected ? palette.accent : palette.text,
        ),
      ),
    );
  }
}
