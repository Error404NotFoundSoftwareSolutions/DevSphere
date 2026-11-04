// User story: US-06 Browse the lab catalogue (Sprint 2, MVP)
// Requirements: FR-CAT-001..003, FR-PROG-001
// Implemented here: SAMPLE data for the dashboard, course and lab pages. Nothing here comes from a
// server; every screen that shows it says so. Replace with api_client results when stories land.

class SampleActivity {
  const SampleActivity({
    required this.id,
    required this.kinds,
    required this.title,
    required this.description,
    required this.duration,
    required this.level,
    required this.steps,
  });

  final String id;
  final List<String> kinds; // chips: Featured, Path, Course, Lab
  final String title;
  final String description;
  final String duration;
  final String level;
  final List<String> steps;
}

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

  static const String learner = 'Learner';
  static const int streakWeeks = 1;
  static const int weeklyDone = 1;
  static const int weeklyTarget = 3;
  static const int badgeCount = 2;
  static const int skillCount = 3;

  /// Day circles Thu..Wed; true = at least one unit completed that day.
  static const List<bool> week = [
    false,
    false,
    false,
    false,
    false,
    false,
    true
  ];
  static const List<String> weekLabels = [
    'Thu',
    'Fri',
    'Sat',
    'Sun',
    'Mon',
    'Tue',
    'Wed'
  ];
}
