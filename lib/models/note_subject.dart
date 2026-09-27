import '../database/database.dart';

/// UI-facing alias for the Drift-generated row type.
/// Keeping this indirection means screens/widgets never import
/// `database.dart` directly, so the storage layer can change
/// without touching feature code.
typedef NoteSubjectModel = NoteSubject;
