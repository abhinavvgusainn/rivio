import 'package:flutter/material.dart';

import '../../database/database.dart';
import '../../services/file_service.dart';
import 'widgets/pdf_tile.dart';

/// PDFs inside one Notes subject.
class NoteSubjectScreen extends StatefulWidget {
  const NoteSubjectScreen({
    super.key,
    required this.database,
    required this.subject,
  });

  final AppDatabase database;
  final NoteSubject subject;

  @override
  State<NoteSubjectScreen> createState() => _NoteSubjectScreenState();
}

class _NoteSubjectScreenState extends State<NoteSubjectScreen> {
  final _fileService = FileService();

  Future<void> _addPdf() async {
    final picked = await _fileService.pickPdf();
    if (picked == null) return;
    await widget.database.addNoteFile(
      subjectId: widget.subject.id,
      fileName: picked.fileName,
      filePath: picked.filePath,
    );
  }

  Future<void> _openPdf(NoteFile file) async {
    final error = await _fileService.openPdf(file.filePath);
    if (error != null && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not open PDF: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.subject.name)),
      floatingActionButton: FloatingActionButton(
        onPressed: _addPdf,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<NoteFile>>(
        stream: widget.database.watchNoteFiles(widget.subject.id),
        builder: (context, snapshot) {
          final files = snapshot.data ?? const [];

          if (files.isEmpty) {
            return const Center(child: Text('Add a PDF to this subject'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: files.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final file = files[index];
              return PdfTile(
                file: file,
                onTap: () => _openPdf(file),
                onDelete: () => widget.database.deleteNoteFile(file.id),
              );
            },
          );
        },
      ),
    );
  }
}
