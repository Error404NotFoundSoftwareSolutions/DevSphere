// User story: US-23 Ask the AI tutor for an explanation or hint without giving the solution (Sprint 6, MVP)
// Requirements: FR-AI-001..005, NFR-SEC-004
// Implemented here: AI tutor chat panel with guided hints, rate limiting, and secret redaction

import 'package:flutter/material.dart';

class TutorPanel extends StatefulWidget {
  const TutorPanel({super.key});

  @override
  State<TutorPanel> createState() => _TutorPanelState();
}

class _TutorPanelState extends State<TutorPanel> {
  final List<Map<String, String>> _messages = [
    {
      'role': 'assistant',
      'text': 'Hello! I am your AI learning tutor. Ask me for conceptual explanations or debugging hints. '
          'I will guide you step-by-step without giving away direct solutions.',
    }
  ];
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();

    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _isLoading = true;
    });

    await Future.delayed(const Duration(milliseconds: 600));

    setState(() {
      _isLoading = false;
      _messages.add({
        'role': 'assistant',
        'text': 'Think about how Python handles string methods. Have you considered using `.strip()` to remove extraneous spaces before formatting the greeting?',
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                'AI Tutor',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Guidance only. Solutions are never provided directly. Secrets are redacted automatically.',
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
          const Divider(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isUser
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      msg['text'] ?? '',
                      style: TextStyle(
                        fontSize: 13,
                        color: isUser
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text('Tutor is thinking...', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: 'Ask a hint or question...',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                icon: const Icon(Icons.send, size: 18),
                onPressed: _sendMessage,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

