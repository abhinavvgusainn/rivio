import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../app/widgets/study_widgets.dart';
import '../../database/database.dart';
import '../../services/file_service.dart';
import 'note_subject_screen.dart';
import 'widgets/add_subject_dialog.dart';
import 'widgets/note_subject_card.dart';
import 'widgets/pdf_tile.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key, required this.database});
  final AppDatabase database;

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final _searchController = TextEditingController();
  final _fileService = FileService();
  bool _searching = false;
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _addSubject() async {
    final name = await showAddSubjectDialog(context, title: 'Add subject');
    if (name != null && mounted) await widget.database.createNoteSubject(name);
  }

  Future<void> _openFile(NoteFile file) async {
    final error = await _fileService.openPdf(file.filePath);
    if (error != null && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not open PDF: $error')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: StreamBuilder<List<NoteSubject>>(
      stream: widget.database.watchNoteSubjects(),
      builder: (context, subjectSnapshot) => StreamBuilder<List<NoteFile>>(
        stream: widget.database.watchAllNoteFiles(),
        builder: (context, fileSnapshot) {
          final subjects = subjectSnapshot.data ?? const <NoteSubject>[];
          final files = fileSnapshot.data ?? const <NoteFile>[];
          final matchingSubjectIds = files
              .where(
                (file) =>
                    file.fileName.toLowerCase().contains(_query.toLowerCase()),
              )
              .map((file) => file.subjectId)
              .toSet();
          final visibleSubjects = subjects
              .where(
                (subject) =>
                    _query.isEmpty ||
                    subject.name.toLowerCase().contains(_query.toLowerCase()) ||
                    matchingSubjectIds.contains(subject.id),
              )
              .toList();
          final matchingFiles = _query.isEmpty
              ? <NoteFile>[]
              : files
                    .where(
                      (file) => file.fileName.toLowerCase().contains(
                        _query.toLowerCase(),
                      ),
                    )
                    .toList();

          final slivers = <Widget>[
            StudySliverAppBar(onSearch: _toggleSearch),
            if (_searching)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 14),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _query = value.trim()),
                    decoration: InputDecoration(
                      hintText: 'Search subjects or documents…',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                        icon: const Icon(Icons.close),
                      ),
                    ),
                  ),
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'Notes',
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
              sliver: SliverToBoxAdapter(child: _infoCard()),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 22, 18, 10),
              sliver: SliverToBoxAdapter(
                child: _folderHeading(subjects.length),
              ),
            ),
          ];

          if (visibleSubjects.isEmpty) {
            slivers.add(
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                sliver: SliverToBoxAdapter(
                  child: EmptyState(
                    icon: Icons.folder_open_outlined,
                    title: _query.isEmpty
                        ? 'No subjects yet'
                        : 'No matches found',
                    body: _query.isEmpty
                        ? 'Add a subject to start organizing your PDFs.'
                        : 'Try a different subject or file name.',
                    tint: const Color(0xFFEAF5EE),
                  ),
                ),
              ),
            );
          } else {
            slivers.add(
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                sliver: SliverList.separated(
                  itemCount: visibleSubjects.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final subject = visibleSubjects[index];
                    final count = files
                        .where((file) => file.subjectId == subject.id)
                        .length;
                    return NoteSubjectCard(
                      subject: subject,
                      fileCount: count,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => NoteSubjectScreen(
                            database: widget.database,
                            subject: subject,
                          ),
                        ),
                      ),
                      onDelete: () =>
                          widget.database.deleteNoteSubject(subject.id),
                    );
                  },
                ),
              ),
            );
          }

          if (matchingFiles.isNotEmpty) {
            slivers.add(
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(18, 22, 18, 10),
                sliver: SliverToBoxAdapter(
                  child: SectionHeading(title: 'Matching PDFs'),
                ),
              ),
            );
            slivers.add(
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                sliver: SliverList.separated(
                  itemCount: matchingFiles.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final file = matchingFiles[index];
                    return PdfTile(
                      file: file,
                      onTap: () => _openFile(file),
                      onDelete: () => widget.database.deleteNoteFile(file.id),
                    );
                  },
                ),
              ),
            );
          }
          slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 30)));
          return CustomScrollView(slivers: slivers);
        },
      ),
    ),
  );

  void _toggleSearch() {
    setState(() {
      _searching = !_searching;
      if (!_searching) {
        _query = '';
        _searchController.clear();
      }
    });
  }

  Widget _folderHeading(int count) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth < 380;
      return Row(
        children: [
          const Expanded(
            child: Text(
              'Subject Folders',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF2F0),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '$count Active',
              style: const TextStyle(
                color: RivioColors.secondaryText,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: _addSubject,
            icon: const Icon(Icons.add, size: 18),
            label: Text(compact ? 'Add' : 'Add Subject'),
            style: OutlinedButton.styleFrom(
              foregroundColor: RivioColors.green,
              side: const BorderSide(color: RivioColors.green),
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 8 : 12,
                vertical: 10,
              ),
            ),
          ),
        ],
      );
    },
  );

  Widget _infoCard() => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: RivioColors.border),
    ),
    child: const Row(
      children: [
        CircleAvatar(
          backgroundColor: Color(0xFFE8F0EB),
          child: Icon(Icons.folder_copy_outlined, color: RivioColors.green),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            "Notes reference your device's PDF files directly without moving them.",
            style: TextStyle(color: RivioColors.secondaryText, height: 1.35),
          ),
        ),
      ],
    ),
  );
}
