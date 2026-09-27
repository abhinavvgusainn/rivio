import 'package:flutter/material.dart';

import '../../database/database.dart';
import 'note_subject_screen.dart';
import 'widgets/add_subject_dialog.dart';
import 'widgets/note_subject_card.dart';

/// Top-level Notes screen: a list of subjects, each holding PDFs.
/// This is a PDF organizer, not a text-note editor.
class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key, required this.database});

  final AppDatabase database;

  Future<void> _createSubject(BuildContext context) async {
    final name = await showAddSubjectDialog(context, title: 'New subject');
    if (name == null || name.isEmpty) return;
    await database.createNoteSubject(name);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notes')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createSubject(context),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<NoteSubject>>(
        stream: database.watchNoteSubjects(),
        builder: (context, snapshot) {
          final subjects = snapshot.data ?? const [];

          if (subjects.isEmpty) {
            return const Center(
              child: Text('Add a subject to start organizing PDFs'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: subjects.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final subject = subjects[index];
              return StreamBuilder<List<NoteFile>>(
                stream: database.watchNoteFiles(subject.id),
                builder: (context, fileSnapshot) {
                  final fileCount = fileSnapshot.data?.length ?? 0;
                  return NoteSubjectCard(
                    subject: subject,
                    fileCount: fileCount,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => NoteSubjectScreen(
                          database: database,
                          subject: subject,
                        ),
                      ),
                    ),
                    onDelete: () => database.deleteNoteSubject(subject.id),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
