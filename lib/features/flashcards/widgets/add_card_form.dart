import 'package:flutter/material.dart';

class CardDraft {
  const CardDraft(this.front, this.back);
  final String front;
  final String back;
}

Future<CardDraft?> showAddCardForm(
  BuildContext context, {
  String? front,
  String? back,
}) => showModalBottomSheet<CardDraft>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (context) => _AddCardSheet(initialFront: front, initialBack: back),
);

class _AddCardSheet extends StatefulWidget {
  const _AddCardSheet({this.initialFront, this.initialBack});
  final String? initialFront;
  final String? initialBack;
  @override
  State<_AddCardSheet> createState() => _AddCardSheetState();
}

class _AddCardSheetState extends State<_AddCardSheet> {
  late final _front = TextEditingController(text: widget.initialFront);
  late final _back = TextEditingController(text: widget.initialBack);
  final _formKey = GlobalKey<FormState>();
  @override
  void dispose() {
    _front.dispose();
    _back.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.initialFront == null
                  ? 'Create flashcard'
                  : 'Edit flashcard',
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _front,
              autofocus: widget.initialFront == null,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Question',
                hintText: 'Write a clear prompt',
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Add a question'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _back,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Answer',
                hintText: 'Add the explanation or definition',
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Add an answer'
                  : null,
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    Navigator.pop(
                      context,
                      CardDraft(_front.text.trim(), _back.text.trim()),
                    );
                  }
                },
                icon: const Icon(Icons.check),
                label: Text(
                  widget.initialFront == null ? 'Create card' : 'Save changes',
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
