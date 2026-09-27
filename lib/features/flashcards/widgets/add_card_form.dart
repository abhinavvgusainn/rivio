import 'package:flutter/material.dart';

/// Bottom-sheet form for adding a single front/back flashcard.
Future<({String front, String back})?> showAddCardSheet(BuildContext context) {
  final frontController = TextEditingController();
  final backController = TextEditingController();

  return showModalBottomSheet<({String front, String back})>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'New card',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: frontController,
              autofocus: true,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'Front (question)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: backController,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'Back (answer)'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                final front = frontController.text.trim();
                final back = backController.text.trim();
                if (front.isEmpty || back.isEmpty) return;
                Navigator.of(context).pop((front: front, back: back));
              },
              child: const Text('Add card'),
            ),
          ],
        ),
      );
    },
  );
}
