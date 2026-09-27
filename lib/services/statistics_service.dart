import 'package:flutter/material.dart';

import '../database/database.dart';

class DailyStudyActivity {
  const DailyStudyActivity({
    this.timerMinutes = 0,
    this.reviewMinutes = 0,
    this.cardsReviewed = 0,
  });

  final int timerMinutes;
  final int reviewMinutes;
  final int cardsReviewed;

  int get effort => timerMinutes + reviewMinutes + cardsReviewed;
}

class HomeStatistics {
  const HomeStatistics({
    required this.totalStudySeconds,
    required this.totalFocusSeconds,
    required this.todayFocusSeconds,
    required this.focusSessions,
    required this.reviewRounds,
    required this.studyDays,
    required this.currentStreak,
    required this.activity,
  });

  final int totalStudySeconds;
  final int totalFocusSeconds;
  final int todayFocusSeconds;
  final int focusSessions;
  final int reviewRounds;
  final int studyDays;
  final int currentStreak;
  final Map<String, DailyStudyActivity> activity;

  String get totalStudyLabel {
    final minutes = totalStudySeconds ~/ 60;
    if (totalStudySeconds > 0 && minutes == 0) return '<1m';
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    return hours == 0
        ? '${remainingMinutes}m'
        : '${hours}h ${remainingMinutes}m';
  }

  String get totalFocusLabel => _durationLabel(totalFocusSeconds);

  int get effortLastFiveWeeks {
    final today = DateUtils.dateOnly(DateTime.now());
    final currentWeekStart = today.subtract(Duration(days: today.weekday - 1));
    final firstDay = _dayKey(
      currentWeekStart.subtract(const Duration(days: 28)),
    );
    return activity.entries
        .where((entry) => entry.key.compareTo(firstDay) >= 0)
        .fold<int>(0, (sum, entry) => sum + entry.value.effort);
  }

  static String _durationLabel(int seconds) {
    final minutes = seconds ~/ 60;
    if (seconds > 0 && minutes == 0) return '<1m';
    final hours = minutes ~/ 60;
    final remainder = minutes % 60;
    return hours == 0 ? '${remainder}m' : '${hours}h ${remainder}m';
  }

  factory HomeStatistics.fromSessions(
    List<StudySession> sessions,
    List<FlashcardReviewEvent> reviews,
  ) {
    final timerSessions = sessions
        .where((session) => session.type == StudySessionType.pomodoro)
        .toList();
    final completedFocusSessions = timerSessions
        .where((session) => session.completed)
        .toList();
    final reviewRounds = sessions
        .where((session) => session.type == StudySessionType.flashcardReview)
        .toList();
    final activeDays = <DateTime>{};
    final activity = <String, DailyStudyActivity>{};
    final dayFormat = DateUtils.dateOnly;
    void addSession(StudySession session) {
      if (session.durationSeconds <= 0 && session.cardsReviewed <= 0) return;
      final date = session.completedAt;
      final day = dayFormat(date);
      final key = _dayKey(day);
      final current = activity[key] ?? const DailyStudyActivity();
      final minutes = session.durationSeconds ~/ 60;
      final isTimer = session.type == StudySessionType.pomodoro;
      activity[key] = DailyStudyActivity(
        timerMinutes: current.timerMinutes + (isTimer ? minutes : 0),
        reviewMinutes: current.reviewMinutes + (isTimer ? 0 : minutes),
        cardsReviewed: current.cardsReviewed,
      );
      activeDays.add(day);
    }

    for (final session in sessions) {
      addSession(session);
    }
    for (final event in reviews) {
      final day = dayFormat(event.reviewedAt);
      final key = _dayKey(day);
      final current = activity[key] ?? const DailyStudyActivity();
      activity[key] = DailyStudyActivity(
        timerMinutes: current.timerMinutes,
        reviewMinutes: current.reviewMinutes,
        cardsReviewed: current.cardsReviewed + 1,
      );
      activeDays.add(day);
    }

    final today = dayFormat(DateTime.now());
    final todayFocusSeconds = timerSessions
        .where((session) => dayFormat(session.completedAt) == today)
        .fold<int>(0, (sum, session) => sum + session.durationSeconds);
    var streak = 0;
    var cursor = activeDays.contains(today)
        ? today
        : today.subtract(const Duration(days: 1));
    while (activeDays.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    return HomeStatistics(
      totalStudySeconds: sessions.fold(
        0,
        (sum, session) => sum + session.durationSeconds,
      ),
      totalFocusSeconds: timerSessions.fold<int>(
        0,
        (sum, session) => sum + session.durationSeconds,
      ),
      todayFocusSeconds: todayFocusSeconds,
      focusSessions: completedFocusSessions.length,
      reviewRounds: reviewRounds.length,
      studyDays: activeDays.length,
      currentStreak: streak,
      activity: activity,
    );
  }
}

String _dayKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
