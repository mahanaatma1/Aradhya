import 'package:flutter/material.dart';

/// One practice tracked by the Sadhana hub.
///
/// Practices are identified by the same string written into
/// `sadhana_sessions.practice`, so japa rows recorded by the japa screen and
/// habit rows recorded by the habits screen land in one history without either
/// screen knowing about this file.
class Practice {
  /// Matches `sadhana_sessions.practice`. Habits use `habit:<key>`.
  final String key;

  final String labelEn;
  final String labelHi;
  final IconData icon;
  final Color color;

  /// Where the practice is actually done. These routes stay registered
  /// independently so deep links and the home widgets keep working.
  final String? route;

  /// What a session's `count` means, for the row subtitle.
  final String unitEn;
  final String unitHi;

  const Practice({
    required this.key,
    required this.labelEn,
    required this.labelHi,
    required this.icon,
    required this.color,
    this.route,
    this.unitEn = '',
    this.unitHi = '',
  });

  String label(bool hi) => hi ? labelHi : labelEn;
  String unit(bool hi) => hi ? unitHi : unitEn;

  bool get isHabit => key.startsWith('habit:');
}

/// The practices shown on the hub, in order.
///
/// Habits are deliberately collapsed into a single row rather than six: the
/// hub is a summary, and six checkboxes belong on the habits screen where
/// they already live.
const kPractices = <Practice>[
  Practice(
    key: 'japa',
    labelEn: 'Japa',
    labelHi: 'जप',
    icon: Icons.grain_rounded,
    color: Color(0xFFD26A2E),
    route: '/japa',
    unitEn: 'beads',
    unitHi: 'माला',
  ),
  Practice(
    key: 'breathing',
    labelEn: 'Pranayama',
    labelHi: 'प्राणायाम',
    icon: Icons.air_rounded,
    color: Color(0xFF3E7C8C),
    route: '/breathing',
    unitEn: 'sessions',
    unitHi: 'सत्र',
  ),
  Practice(
    key: 'reading',
    labelEn: 'Reading',
    labelHi: 'पाठ',
    icon: Icons.menu_book_rounded,
    color: Color(0xFF6C5A9C),
    route: '/scriptures',
    unitEn: 'verses',
    unitHi: 'श्लोक',
  ),
  Practice(
    key: 'mandir',
    labelEn: 'Mandir',
    labelHi: 'मंदिर',
    icon: Icons.temple_hindu_rounded,
    color: Color(0xFFD9748C),
    route: '/mandir',
    unitEn: 'offerings',
    unitHi: 'अर्पण',
  ),
];

/// A day's totals for one practice.
class DayTotal {
  final String dayStamp;
  final int count;
  final int durationSeconds;
  const DayTotal(this.dayStamp, this.count, this.durationSeconds);
}

/// Everything the hub needs about one practice.
class PracticeSummary {
  final String key;

  /// dayStamp -> count, for the sparkline and heatmap.
  final Map<String, int> byDay;

  final int todayCount;
  final int lifetimeCount;
  final int currentStreak;
  final int longestStreak;

  const PracticeSummary({
    required this.key,
    required this.byDay,
    required this.todayCount,
    required this.lifetimeCount,
    required this.currentStreak,
    required this.longestStreak,
  });

  bool get doneToday => todayCount > 0;
}

/// A per-practice target.
class SadhanaGoal {
  final String practice;
  final int? targetCount;
  final int? targetSeconds;
  final bool active;

  const SadhanaGoal({
    required this.practice,
    this.targetCount,
    this.targetSeconds,
    this.active = true,
  });

  factory SadhanaGoal.fromRow(Map<String, Object?> r) => SadhanaGoal(
        practice: (r['practice'] as String?) ?? '',
        targetCount: r['target_count'] as int?,
        targetSeconds: r['target_s'] as int?,
        active: (r['active'] as int?) != 0,
      );
}

/// Milestones are cumulative and never lost, which is the point — a streak can
/// break, but something already done cannot be undone.
class Milestone {
  final int threshold;
  final String labelEn;
  final String labelHi;
  const Milestone(this.threshold, this.labelEn, this.labelHi);
}

const kJapaMilestones = <Milestone>[
  Milestone(108, 'First mala', 'प्रथम माला'),
  Milestone(1080, 'Ten malas', 'दस माला'),
  Milestone(10800, 'Hundred malas', 'सौ माला'),
  Milestone(108000, 'A thousand malas', 'सहस्र माला'),
];

const kDayMilestones = <Milestone>[
  Milestone(7, 'Seven days', 'सात दिन'),
  Milestone(21, 'Twenty-one days', 'इक्कीस दिन'),
  Milestone(40, 'Forty days', 'चालीस दिन'),
  Milestone(108, 'One hundred and eight days', 'एक सौ आठ दिन'),
];
