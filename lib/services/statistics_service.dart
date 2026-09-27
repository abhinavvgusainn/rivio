import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../database/database.dart';

/// Turns raw [StudySession] rows into the numbers/shapes the Home
/// dashboard needs. Keeping this logic out of the widgets means the
/// widgets can be handed mock data while the DB-backed version of
/// this service is still being wired up.
class StatisticsService {
  const StatisticsService(this._database);

  final AppDatabase _database;

  Stream<HomeStatistics> watchStatistics() {
    return _database.watchAllSessions().map(_computeStatistics);
  }

  HomeStatistics _computeStatistics(List<StudySession> sessions) {
    final totalSeconds =
        sessions.fold<int>(0, (sum, s) => sum + s.durationSeconds);

    final pomodoroCount = sessions
        .where((s) => s.type == StudySessionType.pomodoro)
        .length;

    final flashcardSessionCount = sessions
        .where((s) => s.type == StudySessionType.flashcardReview)
        .length;

    final studyDays = sessions
        .map((s) => DateUtils.dateOnly(s.completedAt))
        .toSet();

    return HomeStatistics(
      currentStreakDays: _computeStreak(studyDays),
      totalStudySeconds: totalSeconds,
      pomodoroSessions: pomodoroCount,
      flashcardReviewSessions: flashcardSessionCount,
      studyDays: studyDays.length,
      activityByDay: _bucketByDay(sessions),
    );
  }

  int _computeStreak(Set<DateTime> studyDays) {
    var streak = 0;
    var cursor = DateUtils.dateOnly(DateTime.now());

    // A day with no session yet (today, before you've studied)
    // doesn't break a streak that's still running from yesterday.
    if (!studyDays.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
    }

    while (studyDays.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Minutes studied per calendar day, keyed by 'yyyy-MM-dd', for the
  /// activity heatmap.
  Map<String, int> _bucketByDay(List<StudySession> sessions) {
    final formatter = DateFormat('yyyy-MM-dd');
    final buckets = <String, int>{};
    for (final s in sessions) {
      final key = formatter.format(s.completedAt);
      buckets[key] = (buckets[key] ?? 0) + (s.durationSeconds ~/ 60);
    }
    return buckets;
  }
}

class HomeStatistics {
  const HomeStatistics({
    required this.currentStreakDays,
    required this.totalStudySeconds,
    required this.pomodoroSessions,
    required this.flashcardReviewSessions,
    required this.studyDays,
    required this.activityByDay,
  });

  final int currentStreakDays;
  final int totalStudySeconds;
  final int pomodoroSessions;
  final int flashcardReviewSessions;
  final int studyDays;

  /// 'yyyy-MM-dd' -> minutes studied that day.
  final Map<String, int> activityByDay;

  static const empty = HomeStatistics(
    currentStreakDays: 0,
    totalStudySeconds: 0,
    pomodoroSessions: 0,
    flashcardReviewSessions: 0,
    studyDays: 0,
    activityByDay: {},
  );

  String get totalStudyTimeLabel {
    final hours = totalStudySeconds ~/ 3600;
    final minutes = (totalStudySeconds % 3600) ~/ 60;
    if (hours == 0) return '${minutes}m';
    return '${hours}h ${minutes}m';
  }
}
