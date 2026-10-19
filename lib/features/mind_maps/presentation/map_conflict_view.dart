import 'package:flutter/material.dart';
import 'package:namma_project/core/application/ports/foundation_ports.dart';
import 'package:namma_project/features/mind_maps/application/map_reconciliation.dart';

import 'mind_maps_strings.dart';

/// Read-only evidence: choosing a winner is a separate edit with a new version.
class MapConflictViewPanel extends StatelessWidget {
  const MapConflictViewPanel({
    super.key,
    required this.conflicts,
    required this.strings,
    required this.ownerId,
    this.session,
  });

  final List<MapConflictView> conflicts;
  final MindMapsStrings strings;
  final String ownerId;
  final CloudSessionPort? session;

  @override
  Widget build(BuildContext context) {
    if (session == null) return _content();
    return StreamBuilder<CloudSessionSnapshot>(
      stream: session!.observeSession(),
      builder: (context, snapshot) {
        final value = snapshot.data;
        if (value?.status != CloudSessionStatus.signedIn ||
            value?.accountId != ownerId) {
          return const SizedBox.shrink();
        }
        return _content();
      },
    );
  }

  Widget _content() => Scaffold(
    appBar: AppBar(title: Text(strings.conflicts)),
    body: ListView.builder(
      itemCount: conflicts.length,
      itemBuilder: (context, index) {
        final conflict = conflicts[index];
        return Card(
          key: ValueKey('map-conflict-${conflict.id}'),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (conflict.unresolved) Text(strings.conflictUnresolved),
                Text('${strings.conflictActive}: ${conflict.activeLabel}'),
                Text('${strings.conflictRetained}: ${conflict.retainedLabel}'),
              ],
            ),
          ),
        );
      },
    ),
  );
}
