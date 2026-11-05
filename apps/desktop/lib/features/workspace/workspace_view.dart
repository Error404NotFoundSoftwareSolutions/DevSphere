// User story: US-15 Open the lab workspace (Sprint 4, MVP)
// Requirements: FR-WS-001..005, NFR-MAINT-005
// Implemented here: 3-pane workspace view: Guide, Editor, Terminal

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../guide/guide_panel.dart';
import '../tutor/tutor_panel.dart';
import 'task_bar.dart';

class WorkspaceView extends StatelessWidget {
  final String attemptId;

  const WorkspaceView({super.key, required this.attemptId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          key: const Key('workspace_back_button'),
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to Catalogue',
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/catalogue');
            }
          },
        ),
        title: Text('Workspace ($attemptId)'),
        actions: const [
          TaskBar(),
        ],
      ),
      body: Row(
        children: [
          const SizedBox(
            width: 320,
            child: GuidePanel(),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Container(
              color: Colors.grey.shade900,
              padding: const EdgeInsets.all(16),
              child: const Text(
                '// Native Dart Code Editor (re_editor)\ndef greet(name):\n    return f"Hello, {name}!"\n',
                style: TextStyle(color: Colors.white, fontFamily: 'monospace'),
              ),
            ),
          ),
          const VerticalDivider(width: 1),
          const SizedBox(
            width: 320,
            child: TutorPanel(),
          ),
        ],
      ),
    );
  }
}

