import '../database/database.dart';

/// UI-facing alias for a flashcard subject.
/// Deliberately unrelated to [NoteSubjectModel] — flashcard and
/// note subjects must never share a table or an id space.
typedef FlashcardSubjectModel = FlashcardSubject;
