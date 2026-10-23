import 'package:flutter/material.dart';

import '../../domain/today_agenda.dart';
import '../today_state.dart';
import '../today_strings.dart';
import 'today_task_list.dart';

class TodayAgendaSection extends StatelessWidget {
  const TodayAgendaSection({
    super.key,
    required this.agenda,
    required this.strings,
    required this.onOpenTasks,
    this.actions = const {},
    this.onSetCompleted,
    this.allowActions = false,
  });

  final TodayAgenda agenda;
  final TodayStrings strings;
  final VoidCallback onOpenTasks;
  final Map<String, TodayActionFeedback> actions;
  final void Function(String, bool)? onSetCompleted;
  final bool allowActions;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(strings.agenda, style: Theme.of(context).textTheme.titleMedium),
      if (agenda.timed.isEmpty && agenda.untimed.isEmpty)
        Text(strings.noTasks)
      else ...[
        if (agenda.timed.isNotEmpty) ...[
          Text(strings.timed, style: Theme.of(context).textTheme.titleSmall),
          TodayTaskList(
            tasks: agenda.timed,
            strings: strings,
            actions: actions,
            onSetCompleted: onSetCompleted,
            allowActions: allowActions,
            onOpenTasks: onOpenTasks,
          ),
        ],
        if (agenda.untimed.isNotEmpty) ...[
          Text(strings.untimed, style: Theme.of(context).textTheme.titleSmall),
          TodayTaskList(
            tasks: agenda.untimed,
            strings: strings,
            actions: actions,
            onSetCompleted: onSetCompleted,
            allowActions: allowActions,
            onOpenTasks: onOpenTasks,
          ),
        ],
      ],
    ],
  );
}
