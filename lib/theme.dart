import 'package:flutter/material.dart';

/// Tokens from the site's "Daily Sheet" design system (src/styles/app.css).
class Sheet {
  static const bg = Color(0xFFF6F4EF);
  static const surface = Color(0xFFFFFFFF);
  static const surface2 = Color(0xFFEEEBE4);
  static const ink = Color(0xFF141C28);
  static const text = Color(0xFF1A2230);
  static const text2 = Color(0xFF4B5566);
  static const text3 = Color(0xFF5B6575);
  static const border = Color(0xFFE2DED5);
  static const primary = Color(0xFF163A63);
  static const primarySoft = Color(0xFFE5EDF6);
  static const accent = Color(0xFFA8611A);
  static const accentText = Color(0xFF8A4C10);
  static const accentSoft = Color(0xFFFBEFDD);
  static const badFg = Color(0xFFA32218);
  static const badBg = Color(0xFFFBE7E4);
  static const warnFg = Color(0xFF7A4B00);
  static const warnBg = Color(0xFFFCEFD2);

  static const serif = 'SourceSerif4';
}

class AdType {
  const AdType(this.slug, this.label, this.short, this.icon, this.bg, this.fg, this.solid);
  final String slug;
  final String label;
  final String short;
  final IconData icon;
  final Color bg;
  final Color fg;
  final Color solid;

  String get path => '/category/$slug';

  static const all = [
    AdType('jobs', 'Jobs', 'Government and private vacancies', Icons.work_outline, Color(0xFFE1F3E7), Color(0xFF14532D), Color(0xFF1E7A3E)),
    AdType('tender', 'Tenders', 'Procurement, bids and EOIs', Icons.gavel_outlined, Color(0xFFFDEBDD), Color(0xFF7A2E0E), Color(0xFFC2410C)),
    AdType('admission', 'Admissions', 'Universities, colleges and courses', Icons.school_outlined, Color(0xFFEEE9FB), Color(0xFF4A2A99), Color(0xFF6D4BD9)),
    AdType('notice', 'Notices', 'Public and official notices', Icons.campaign_outlined, Color(0xFFE9EDF3), Color(0xFF33415A), Color(0xFF5B6B84)),
    AdType('property', 'Property', 'Sale, rent and allotment', Icons.home_work_outlined, Color(0xFFDFF3F0), Color(0xFF0E5A52), Color(0xFF138A76)),
    AdType('court', 'Court Notices', 'Summons, proclamations and hearings', Icons.balance_outlined, Color(0xFFFBE6E6), Color(0xFF8A2323), Color(0xFFB93636)),
    AdType('auction', 'Auctions', 'Auctions of goods and property', Icons.sell_outlined, Color(0xFFFBF0D4), Color(0xFF6B4306), Color(0xFFA16A07)),
    AdType('result', 'Results', 'Exam, merit list and selection results', Icons.fact_check_outlined, Color(0xFFE0EFFB), Color(0xFF16467A), Color(0xFF2B6CB0)),
  ];

  static const other = AdType('other', 'Ads', '', Icons.article_outlined, Color(0xFFECEBE7), Color(0xFF3D4350), Color(0xFF6B7280));

  static AdType byLabel(String? label) {
    if (label == null) return other;
    final l = label.toLowerCase();
    for (final t in all) {
      if (t.label.toLowerCase() == l || t.slug == l) return t;
    }
    return other;
  }
}

/// Major cities with their dailyads.pk slugs.
const popularCities = [
  ('Islamabad', 'islamabad'),
  ('Lahore', 'lahore'),
  ('Karachi', 'karachi'),
  ('Peshawar', 'peshawar'),
  ('Rawalpindi', 'rawalpindi'),
  ('Quetta', 'quetta'),
  ('Multan', 'multan'),
  ('Faisalabad', 'faisalabad'),
  ('Hyderabad', 'hyderabad'),
  ('Gujranwala', 'gujranwala'),
  ('Sargodha', 'sargodha'),
  ('Sukkur', 'sukkur'),
  ('Sialkot', 'sialkot'),
  ('Bahawalpur', 'bahawalpur'),
  ('Rahim Yar Khan', 'rahim-yar-khan'),
  ('Abbottabad', 'abbottabad'),
  ('Mardan', 'mardan'),
  ('Sheikhupura', 'sheikhupura'),
  ('Muzaffarabad', 'muzaffarabad'),
  ('Gilgit', 'gilgit'),
];

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: Sheet.primary,
    primary: Sheet.primary,
    surface: Sheet.bg,
    secondary: Sheet.accent,
  ).copyWith(surfaceContainerLowest: Sheet.surface, onSurface: Sheet.text, outlineVariant: Sheet.border);

  final base = ThemeData(useMaterial3: true, colorScheme: scheme, scaffoldBackgroundColor: Sheet.bg);
  return base.copyWith(
    textTheme: base.textTheme.apply(bodyColor: Sheet.text, displayColor: Sheet.text).copyWith(
          headlineSmall: const TextStyle(fontFamily: Sheet.serif, fontWeight: FontWeight.w700, fontSize: 24, color: Sheet.text, height: 1.2),
          titleLarge: const TextStyle(fontFamily: Sheet.serif, fontWeight: FontWeight.w700, fontSize: 20, color: Sheet.text),
          titleMedium: const TextStyle(fontFamily: Sheet.serif, fontWeight: FontWeight.w600, fontSize: 16.5, color: Sheet.text, height: 1.3),
        ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Sheet.bg,
      foregroundColor: Sheet.text,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 1,
      titleTextStyle: TextStyle(fontFamily: Sheet.serif, fontWeight: FontWeight.w700, fontSize: 20, color: Sheet.text),
    ),
    cardTheme: CardThemeData(
      color: Sheet.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Sheet.border)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Sheet.surface,
      indicatorColor: Sheet.primarySoft,
      surfaceTintColor: Colors.transparent,
      labelTextStyle: WidgetStateProperty.all(const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: Sheet.surface,
      side: const BorderSide(color: Sheet.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    dividerTheme: const DividerThemeData(color: Sheet.border, space: 1),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Sheet.surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Sheet.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Sheet.border)),
    ),
  );
}
