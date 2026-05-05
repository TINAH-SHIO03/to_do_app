import 'package:flutter/material.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String? payload =
        ModalRoute.of(context)?.settings.arguments as String?;

    String title = 'No Title';
    String note = 'No Note';

    if (payload != null && payload.contains('|')) {
      final List<String> parts = payload.split('|');
      if (parts.length >= 2) {
        final type = parts[0].toLowerCase();
        if (type == 'theme') {
          title = 'Theme Change';
          final value = parts[1].toLowerCase();
          note = 'Theme changed to ${value == 'dark' ? 'dark' : 'light'} mode';
        } else if (type == 'task') {
          title = 'Task Reminder';
          note = parts.length > 2 ? parts[2] : 'Task starts soon';
        } else {
          // Fallback
          title = parts.length > 1 ? parts[1] : 'No Title';
          note = parts.length > 2 ? parts[2] : 'No Note';
        }
      }
    }

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Notification Details')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Title: $title',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text('Note: $note', style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
