import 'package:flutter/material.dart';

/// Simple name-entry dialog reused for creating a note subject
/// (and, by the flashcards feature, a flashcard subject/deck).
Future<String?> showAddSubjectDialog(
  BuildContext context, {
  required String title,
  String hint = 'Name',
}) {
  final controller = TextEditingController();

  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: InputDecoration(hintText: hint),
        onSubmitted: (value) => Navigator.of(context).pop(value.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(context).pop(controller.text.trim()),
          child: const Text('Create'),
        ),
      ],
    ),
  );
}
