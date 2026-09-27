import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../database/database.dart';
import '../../services/statistics_service.dart';
import 'widgets/activity_heatmap.dart';
import 'widgets/radar_chart.dart';
import 'widgets/statistics_card.dart';
import 'widgets/streak_card.dart';

/// Study statistics dashboard. Read-only — all data here is derived
/// from Pomodoro sessions and flashcard reviews logged elsewhere.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.database});

  final AppDatabase database;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final StatisticsService _statisticsService;

  @override
  void initState() {
    super.initState();
    _statisticsService = StatisticsService(widget.database);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: StreamBuilder<HomeStatistics>(
        stream: _statisticsService.watchStatistics(),
        builder: (context, snapshot) {
          final stats = snapshot.data ?? HomeStatistics.empty;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              StreakCard(streakDays: stats.currentStreakDays),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  StatisticsCard(
                    label: 'Total study time',
                    value: stats.totalStudyTimeLabel,
                    icon: Icons.schedule,
                  ),
                  StatisticsCard(
                    label: 'Pomodoro sessions',
                    value: '${stats.pomodoroSessions}',
                    icon: Icons.timer_outlined,
                  ),
                  StatisticsCard(
                    label: 'Flashcards reviewed',
                    value: '${stats.flashcardReviewSessions}',
                    icon: Icons.style_outlined,
                  ),
                  StatisticsCard(
                    label: 'Study days',
                    value: '${stats.studyDays}',
                    icon: Icons.calendar_today_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Activity',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: RivioColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ActivityHeatmap(minutesByDay: stats.activityByDay),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Study distribution',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: RivioColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // TODO: replace with a real per-subject
                      // breakdown once sessions are tagged by subject.
                      const StudyRadarChart(distribution: {}),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
