import 'package:flutter/material.dart';

import '../services/ads_service.dart';
import '../services/interaction_feedback.dart';

class RivioColors {
  static const background = Color(0xFFF6F8F6);
  static const surface = Color(0xFFFFFFFF);
  static const green = Color(0xFF087447);
  static const greenMid = Color(0xFF168459);
  static const mint = Color(0xFF9EF0C0);
  static const mintSoft = Color(0xFFE1F7EA);
  static const text = Color(0xFF171B19);
  static const secondaryText = Color(0xFF68736C);
  static const border = Color(0xFFD5DED8);
  static const coral = Color(0xFFFF7770);
  static const blue = Color(0xFF65B8E8);
  static const amber = Color(0xFFFFC653);
  static const lavender = Color(0xFF9385D9);
  static const heatmap = [
    Color(0xFFEFF2EF),
    Color(0xFF9EF0C0),
    Color(0xFF51C98B),
    Color(0xFF168459),
    Color(0xFF005D3D),
  ];

  static Color subject(String value) {
    final hex = value.replaceFirst('#', '');
    final parsed = int.tryParse(hex, radix: 16);
    return parsed == null ? green : Color(0xFF000000 | parsed);
  }
}

class RivioTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: RivioColors.green,
        brightness: Brightness.light,
        surface: RivioColors.surface,
      ),
    );
    return base.copyWith(
      scaffoldBackgroundColor: RivioColors.background,
      textTheme: base.textTheme.apply(
        bodyColor: RivioColors.text,
        displayColor: RivioColors.text,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: RivioColors.background,
        foregroundColor: RivioColors.text,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: RivioColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: RivioColors.border),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: RivioColors.surface,
        indicatorColor: RivioColors.mint,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: RivioColors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF3F5F3),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: RivioColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: RivioColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: RivioColors.green, width: 1.5),
        ),
      ),
    );
  }
}

class StudySliverAppBar extends StatelessWidget {
  const StudySliverAppBar({super.key, this.onSearch, this.title = 'Rivio'});

  final VoidCallback? onSearch;
  final String title;

  @override
  Widget build(BuildContext context) => SliverAppBar(
    floating: true,
    snap: true,
    pinned: false,
    toolbarHeight: 62,
    titleSpacing: 18,
    title: Row(
      children: [
        const Icon(Icons.menu_book_rounded, color: RivioColors.green, size: 25),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: RivioColors.text,
          ),
        ),
      ],
    ),
    actions: [
      if (onSearch != null)
        IconButton(
          onPressed: onSearch,
          icon: const Icon(Icons.search_rounded),
          tooltip: 'Search',
        ),
      IconButton(
        onPressed: () => showStudySettings(context),
        icon: const Icon(Icons.settings_outlined),
        tooltip: 'Settings',
      ),
      const SizedBox(width: 8),
    ],
  );
}

Future<void> showStudySettings(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Settings',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              StatefulBuilder(
                builder: (context, setState) => SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Sound and haptics'),
                  subtitle: const Text(
                    'Play a cue when you study and finish a session',
                  ),
                  value: InteractionFeedback.enabled,
                  onChanged: (enabled) =>
                      setState(() => InteractionFeedback.setEnabled(enabled)),
                ),
              ),
              ValueListenableBuilder<bool>(
                valueListenable:
                    AdsService.instance.privacyOptionsRequiredNotifier,
                builder: (context, required, _) => required
                    ? ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.privacy_tip_outlined),
                        title: const Text('Privacy options'),
                        onTap: () => AdsService.instance.showPrivacyOptions(),
                      )
                    : const SizedBox.shrink(),
              ),
              const ListTile(
                leading: Icon(Icons.insights_outlined),
                title: Text('Rivio'),
                subtitle: Text('Your personal study tracker'),
              ),
            ],
          ),
        ),
      ),
    );
