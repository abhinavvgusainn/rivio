import '../database/database.dart';

/// A PDF reference belonging to a [NoteSubjectModel].
/// Only the file's path/URI + display metadata are stored;
/// the PDF bytes stay on the device's filesystem.
typedef PdfDocument = NoteFile;
