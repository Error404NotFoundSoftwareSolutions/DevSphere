// User story: US-06 Browse the lab catalogue (Sprint 2, MVP)
// Requirements: FR-CAT-001..003, FR-PROG-001
// Implemented here: the catalogue (what exists and what is planned) and the learning paths. This part is
// static and the same for everyone. Progress, streaks and credentials are NOT here: they come from the signed-in
// person's own data (lib/data). Replace with api_client results when the catalogue API lands.

import '../../data/user_data.dart';

class SampleActivity {
  const SampleActivity({
    required this.id,
    required this.kinds,
    required this.title,
    required this.description,
    required this.duration,
    required this.level,
    required this.steps,
    this.available = false,
    this.skills = const [],
  });

  final String id;
  final List<String> kinds; // chips: Featured, Path, Course, Lab
  final String title;
  final String description;
  final String duration;
  final String level;
  final List<String> steps;

  /// True when the lab's content is in this install, so Start works. Others are planned.
  final bool available;

  /// Skills a learner practises here. Shown on the Credentials page once the lab's checks all pass.
  final List<String> skills;
}

/// Finds an activity for the lab page: a catalogue item, or a lab the AI wrote for this person.
SampleActivity activityFor(String id, UserData? data) {
  final known = SampleData.find(id);
  if (known != null) return known;
  for (final g in data?.generatedLabs ?? const <GeneratedLabRef>[]) {
    if (g.labId == id) return generatedActivity(g);
  }
  return SampleData.activities.first;
}

SampleActivity generatedActivity(GeneratedLabRef g) => SampleActivity(
      id: g.labId,
      kinds: const ['Lab', 'AI-generated'],
      title: g.title,
      description:
          'Written by AI for: ${g.topic}. It has not been reviewed by a person.',
      duration: '30 minutes',
      level: 'Beginner',
      steps: const [],
      available: true,
      skills: const [],
    );

class SampleData {
  const SampleData._();

  static const List<SampleActivity> activities = [
    SampleActivity(
      id: 'python-hello-001',
      kinds: ['Featured', 'Lab'],
      title: 'Hello, Python: set up, install and run',
      description:
          'Set up a project, write your first function and check it with automated tests.',
      duration: '45 minutes',
      level: 'Beginner',
      steps: ['Setup', 'Write the greet function', 'Run the checks'],
      available: true,
      skills: ['Python basics', 'Writing a function', 'Running tests'],
    ),
    SampleActivity(
      id: 'oss-first-contribution-001',
      kinds: ['Featured', 'Lab'],
      title: 'Your first open-source contribution',
      description:
          'Learn how open source works, then do it: fix two bugs and a docs issue with real Git branches, commits, a pull request description and a review.',
      duration: '2.5 hours',
      level: 'Beginner',
      steps: [
        'Theory and videos',
        'Start a repository',
        'Fix issues on branches',
        'Write the pull request',
        'Answer the review'
      ],
      available: true,
      skills: [
        'Git branches and merges',
        'Commit messages',
        'Regression tests',
        'Pull request writing',
        'Responding to review',
      ],
    ),
    SampleActivity(
      id: 'git-first-commit-001',
      kinds: ['Featured', 'Course'],
      title: 'Your first Git commit',
      description:
          'Create a repository, stage changes and write a clear commit message you can be proud of.',
      duration: '1 hour',
      level: 'Beginner',
      steps: ['Setup', 'Stage and commit', 'Review history'],
    ),
    SampleActivity(
      id: 'debug-a-traceback-001',
      kinds: ['Featured', 'Course'],
      title: 'Read a stack trace and fix the bug',
      description:
          'Find the failing line, understand the error message and fix a small bug with the tests as your guide.',
      duration: '1 hour',
      level: 'Beginner',
      steps: ['Setup', 'Find the error', 'Fix and verify'],
    ),
    SampleActivity(
      id: 'first-pull-request-001',
      kinds: ['Path'],
      title: 'From zero to your first pull request',
      description:
          'Fork a practice repository, fix a real-style issue and respond to review, step by step.',
      duration: '6 hours',
      level: 'Intermediate',
      steps: [
        'Setup',
        'Pick an issue',
        'Open the pull request',
        'Respond to review'
      ],
    ),
    SampleActivity(
      id: 'terminal-basics-001',
      kinds: ['Course'],
      title: 'Terminal basics for developers',
      description:
          'Move around, read files, use environment variables and combine commands with pipes.',
      duration: '1 hour',
      level: 'Beginner',
      steps: ['Setup', 'Navigate', 'Pipes'],
    ),
    SampleActivity(
      id: 'rest-api-001',
      kinds: ['Lab'],
      title: 'Build your first REST API',
      description:
          'Create a REST API with Python, FastAPI and SQLite and validate it with automated tests.',
      duration: '3 hours',
      level: 'Intermediate',
      steps: ['Setup', 'Create endpoints', 'Add tests'],
    ),
  ];

  static SampleActivity byId(String id) =>
      activities.firstWhere((a) => a.id == id, orElse: () => activities.first);

  /// Looks an activity up by id, or null when it is not in the catalogue.
  static SampleActivity? find(String id) {
    for (final a in activities) {
      if (a.id == id) return a;
    }
    return null;
  }

  static const List<LearningPath> paths = [
    LearningPath(
      id: 'first-project-to-first-pr',
      title: 'From your first project to your first pull request',
      description:
          'Write and test code, learn Git properly, then contribute to a project the way maintainers expect.',
      activityIds: [
        'python-hello-001',
        'git-first-commit-001',
        'oss-first-contribution-001',
      ],
    ),
    LearningPath(
      id: 'debug-like-a-professional',
      title: 'Debug like a professional',
      description:
          'Use the terminal, read stack traces and fix bugs with tests as your guide.',
      activityIds: [
        'terminal-basics-001',
        'debug-a-traceback-001',
        'rest-api-001',
      ],
    ),
  ];
}

/// An ordered list of activities. Progress through it is computed from the person's own results.
class LearningPath {
  const LearningPath({
    required this.id,
    required this.title,
    required this.description,
    required this.activityIds,
  });

  final String id;
  final String title;
  final String description;
  final List<String> activityIds;
}
