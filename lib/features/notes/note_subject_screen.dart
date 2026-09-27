import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../app/widgets/study_widgets.dart';
import '../../database/database.dart';
import '../../services/ads_service.dart';
import '../../services/file_service.dart';
import 'widgets/pdf_tile.dart';

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
  bool _selecting = false;

  Future<void> _addPdf() async {
    if (_selecting) return;
    setState(() => _selecting = true);
    try {
      final picked = await _fileService.pickPdf();
      if (picked != null) {
        await widget.database.addNoteFile(
          subjectId: widget.subject.id,
          fileName: picked.fileName,
          filePath: picked.filePath,
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not select that PDF: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _selecting = false);
    }
  }

  Future<void> _openPdf(NoteFile file) async {
    final error = await _fileService.openPdf(file.filePath);
    if (error != null && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not open PDF: $error')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _selecting ? null : _addPdf,
      backgroundColor: RivioColors.green,
      foregroundColor: Colors.white,
      icon: _selecting
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.note_add_outlined),
      label: Text(_selecting ? 'Opening picker' : 'Add PDF'),
    ),
    body: StreamBuilder<List<NoteFile>>(
      stream: widget.database.watchNoteFiles(widget.subject.id),
      builder: (context, snapshot) {
        final files = snapshot.data ?? const <NoteFile>[];
        return CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              snap: true,
              leading: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
              ),
              title: Text(
                widget.subject.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.subject.name} · ${files.length} PDFs',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'PDFs stay in their original device location. Rivio keeps a link for quick access.',
                      style: TextStyle(color: RivioColors.secondaryText),
                    ),
                  ],
                ),
              ),
            ),
            if (files.isEmpty)
              const SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 18),
                sliver: SliverToBoxAdapter(
                  child: EmptyState(
                    icon: Icons.picture_as_pdf_outlined,
                    title: 'No PDFs yet',
                    body: 'Use Add PDF to choose a file from your device.',
                    tint: Color(0xFFFFF0EF),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                sliver: SliverList.separated(
                  itemCount: files.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 9),
                  itemBuilder: (context, index) {
                    final file = files[index];
                    return PdfTile(
                      file: file,
                      onTap: () => _openPdf(file),
                      onDelete: () => widget.database.deleteNoteFile(file.id),
                    );
                  },
                ),
              ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(18, 20, 18, 112),
              sliver: SliverToBoxAdapter(
                child: InlineNativeAd(
                  adUnitId: AdsService.instance.subjectNativeAdUnitId,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        );
      },
    ),
  );
}
