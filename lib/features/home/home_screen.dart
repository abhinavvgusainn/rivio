import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../app/widgets/study_widgets.dart';
import '../../database/database.dart';
import '../../services/statistics_service.dart';
import 'widgets/activity_heatmap.dart';
import 'widgets/radar_chart.dart';
import 'widgets/streak_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.database});
  final AppDatabase database;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _period = 'This Week';

  DateTime? get _since {
    final now = DateTime.now();
    if (_period == 'All Time') return null;
    if (_period == 'This Month') return DateTime(now.year, now.month);
    final today = DateUtils.dateOnly(now);
    return today.subtract(Duration(days: today.weekday - 1));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: StreamBuilder<List<StudySession>>(
      stream: widget.database.watchAllSessions(),
      builder: (context, sessionSnapshot) =>
          StreamBuilder<List<FlashcardReviewEvent>>(
            stream: widget.database.watchReviewEvents(),
            builder: (context, reviewSnapshot) {
              final stats = HomeStatistics.fromSessions(
                sessionSnapshot.data ?? const [],
                reviewSnapshot.data ?? const [],
              );
              return CustomScrollView(
                slivers: [
                  const StudySliverAppBar(),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                    sliver: SliverList.list(
                      children: [
                        StreakCard(streakDays: stats.currentStreak),
                        const SizedBox(height: 14),
                        StreamBuilder<List<SubjectEffort>>(
                          stream: widget.database.watchSubjectEfforts(),
                          builder: (context, effortSnapshot) {
                            final efforts =
                                effortSnapshot.data ?? const <SubjectEffort>[];
                            final cardsMade = efforts.fold<int>(
                              0,
                              (sum, item) => sum + item.cardsCreated,
                            );
                            final sessionsDone =
                                stats.focusSessions + stats.reviewRounds;
                            return SizedBox(
                              height: 112,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: MetricCard(
                                      icon: Icons.timer_outlined,
                                      label: 'Study Time',
                                      value: stats.totalStudyLabel,
                                      tint: const Color(0xFFDFF5E7),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: MetricCard(
                                      icon: Icons.layers_outlined,
                                      label: 'Flashcards',
                                      value: '$cardsMade',
                                      tint: const Color(0xFFE4F1F8),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: MetricCard(
                                      icon: Icons.check_circle_outline,
                                      label: 'Done sessions',
                                      value: '$sessionsDone',
                                      tint: const Color(0xFFFFF1CF),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SectionHeading(
                                  title: 'Study Distribution',
                                  trailing: PopupMenuButton<String>(
                                    initialValue: _period,
                                    onSelected: (period) =>
                                        setState(() => _period = period),
                                    itemBuilder: (context) => const [
                                      PopupMenuItem(
                                        value: 'This Week',
                                        child: Text('This Week'),
                                      ),
                                      PopupMenuItem(
                                        value: 'This Month',
                                        child: Text('This Month'),
                                      ),
                                      PopupMenuItem(
                                        value: 'All Time',
                                        child: Text('All Time'),
                                      ),
                                    ],
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 11,
                                        vertical: 7,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F4F1),
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(
                                          color: RivioColors.border,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Text(
                                            _period,
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(
                                            Icons.keyboard_arrow_down,
                                            size: 16,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 5),
                                const Text(
                                  'Subject effort combines cards made and cards reviewed.',
                                  style: TextStyle(
                                    color: RivioColors.secondaryText,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                StreamBuilder<List<SubjectEffort>>(
                                  stream: widget.database.watchSubjectEfforts(
                                    since: _since,
                                  ),
                                  builder: (context, effortSnapshot) =>
                                      RadarChart(
                                        efforts:
                                            effortSnapshot.data ?? const [],
                                      ),
                                ),
                                const Divider(height: 24),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _FocusSummary(stats: stats),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _CompletionSummary(stats: stats),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SectionHeading(
                                  title: 'Study Activity',
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF1F0),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'Last 5 Weeks',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: RivioColors.secondaryText,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${stats.effortLastFiveWeeks} effort points logged',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: RivioColors.secondaryText,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ActivityHeatmap(
                                  activity: stats.activity,
                                  streak: stats.currentStreak,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
    ),
  );
}

class _FocusSummary extends StatelessWidget {
  const _FocusSummary({required this.stats});
  final HomeStatistics stats;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFF2F4F3),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Focus Time', style: TextStyle(fontSize: 12)),
        const SizedBox(height: 6),
        Text(
          stats.totalFocusLabel,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: (stats.todayFocusSeconds / (4 * 3600)).clamp(0, 1),
            minHeight: 7,
            backgroundColor: const Color(0xFFE0E4E1),
            color: RivioColors.green,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'Daily focus goal: 4h',
          style: TextStyle(fontSize: 10, color: RivioColors.green),
        ),
      ],
    ),
  );
}

class _CompletionSummary extends StatelessWidget {
  const _CompletionSummary({required this.stats});
  final HomeStatistics stats;
  @override
  Widget build(BuildContext context) {
    final percent = (stats.todayFocusSeconds / (4 * 3600) * 100).round().clamp(
      0,
      100,
    );
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F3),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Completion Rate', style: TextStyle(fontSize: 12)),
                const SizedBox(height: 7),
                Text(
                  '$percent%',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  percent >= 100 ? 'Daily target met' : 'Of today’s focus goal',
                  style: const TextStyle(
                    fontSize: 10,
                    color: RivioColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: percent / 100,
                  strokeWidth: 4,
                  backgroundColor: const Color(0xFFDCE3DE),
                  color: RivioColors.green,
                ),
                Text(
                  '$percent%',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
