import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart' show ConflictAlgorithm;

import '../db/user_database.dart';
import 'user_prefs.dart';

/// Per-book scripture reading snapshot (local only).
class BookReadingProgress {
  final int bookId;
  final int? scriptureId;
  final int lastSectionIdx;
  final int sectionsTotal;
  final int sectionsRead;
  final DateTime lastReadAt;
  final DateTime? completedAt;

  const BookReadingProgress({
    required this.bookId,
    this.scriptureId,
    required this.lastSectionIdx,
    required this.sectionsTotal,
    required this.sectionsRead,
    required this.lastReadAt,
    this.completedAt,
  });

  double get fraction =>
      sectionsTotal > 0 ? (sectionsRead / sectionsTotal).clamp(0.0, 1.0) : 0;

  int get percent => (fraction * 100).round();

  bool get isComplete =>
      sectionsTotal > 0 && sectionsRead >= sectionsTotal && completedAt != null;

  factory BookReadingProgress.fromRow(Map<String, Object?> r) =>
      BookReadingProgress(
        bookId: r['book_id'] as int,
        scriptureId: r['scripture_id'] as int?,
        lastSectionIdx: r['last_section_idx'] as int? ?? 0,
        sectionsTotal: r['sections_total'] as int? ?? 0,
        sectionsRead: r['sections_read'] as int? ?? 0,
        lastReadAt: DateTime.fromMillisecondsSinceEpoch(
            r['last_read_at'] as int? ?? 0),
        completedAt: r['completed_at'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(r['completed_at'] as int),
      );
}

/// Aggregates for the You tab.
class ReadingStats {
  final int totalVersesRead;
  final int dayStreak;
  final List<ScriptureReadingSummary> byScripture;

  const ReadingStats({
    required this.totalVersesRead,
    required this.dayStreak,
    required this.byScripture,
  });
}

class ScriptureReadingSummary {
  final int scriptureId;
  final int versesRead;
  final int versesTotal;

  const ScriptureReadingSummary({
    required this.scriptureId,
    required this.versesRead,
    required this.versesTotal,
  });

  double get fraction =>
      versesTotal > 0 ? (versesRead / versesTotal).clamp(0.0, 1.0) : 0;
}

class ReadingProgressController
    extends StateNotifier<Map<int, BookReadingProgress>> {
  ReadingProgressController(this._ref) : super(const {}) {
    _hydrate();
  }

  final Ref _ref;

  BookReadingProgress? get mostRecent {
    BookReadingProgress? best;
    for (final p in state.values) {
      if (best == null || p.lastReadAt.isAfter(best.lastReadAt)) best = p;
    }
    return best;
  }

  ReadingStats stats() {
    final byScripture = <int, ({int read, int total})>{};
    var totalVerses = 0;
    final readDays = <String>{};

    for (final p in state.values) {
      totalVerses += p.sectionsRead;
      readDays.add(dayStampFrom(p.lastReadAt));
      final sid = p.scriptureId;
      if (sid != null) {
        final cur = byScripture[sid] ?? (read: 0, total: 0);
        byScripture[sid] = (
          read: cur.read + p.sectionsRead,
          total: cur.total + p.sectionsTotal,
        );
      }
    }

    return ReadingStats(
      totalVersesRead: totalVerses,
      dayStreak: _readingStreak(readDays),
      byScripture: byScripture.entries
          .map((e) => ScriptureReadingSummary(
                scriptureId: e.key,
                versesRead: e.value.read,
                versesTotal: e.value.total,
              ))
          .toList()
        ..sort((a, b) => b.versesRead.compareTo(a.versesRead)),
    );
  }

  Future<void> _hydrate() async {
    final db = _ref.read(userDatabaseProvider);
    if (db == null) return;
    try {
      final rows = await db.raw.query('reading_progress');
      if (!mounted) return;
      state = {
        for (final r in rows)
          r['book_id'] as int: BookReadingProgress.fromRow(r),
      };
    } catch (e) {
      debugPrint('ReadingProgressController: hydrate failed ($e)');
    }
  }

  /// Backfill [sectionsTotal] the first time a book opens (P3-12).
  Future<void> ensureBookOpen({
    required int bookId,
    required int scriptureId,
    required int sectionsTotal,
  }) async {
    final existing = state[bookId];
    if (existing != null && existing.sectionsTotal > 0) return;

    final db = _ref.read(userDatabaseProvider);
    if (db == null) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    final base = existing ??
        BookReadingProgress(
          bookId: bookId,
          scriptureId: scriptureId,
          lastSectionIdx: 0,
          sectionsTotal: 0,
          sectionsRead: 0,
          lastReadAt: DateTime.fromMillisecondsSinceEpoch(now),
        );

    final next = BookReadingProgress(
      bookId: bookId,
      scriptureId: scriptureId,
      lastSectionIdx: base.lastSectionIdx,
      sectionsTotal: sectionsTotal,
      sectionsRead: base.sectionsRead,
      lastReadAt: base.lastReadAt,
      completedAt: base.completedAt,
    );
    state = {...state, bookId: next};

    try {
      await db.raw.insert(
        'reading_progress',
        {
          'book_id': bookId,
          'scripture_id': scriptureId,
          'last_section_idx': next.lastSectionIdx,
          'sections_total': sectionsTotal,
          'sections_read': next.sectionsRead,
          'last_read_at': next.lastReadAt.millisecondsSinceEpoch,
          'completed_at': next.completedAt?.millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('ReadingProgressController: backfill failed ($e)');
    }
  }

  /// Record the visible section and mirror legacy prefs for one release.
  Future<void> recordSection({
    required int bookId,
    required int? scriptureId,
    required int sectionIndex,
    required int sectionsTotal,
  }) async {
    final now = DateTime.now();
    final prev = state[bookId];
    final prevRead = prev?.sectionsRead ?? 0;
    final read = prev == null
        ? sectionIndex + 1
        : (sectionIndex + 1 > prev.sectionsRead
            ? sectionIndex + 1
            : prev.sectionsRead);
    final total = sectionsTotal > 0
        ? sectionsTotal
        : (prev?.sectionsTotal ?? 0);
    // Stamped ONCE. `read >= total` stays true forever after a book is
    // finished, so re-reading it would otherwise rewrite the completion
    // date on every page turn — and "finished on" would always say today.
    final completed =
        prev?.completedAt ?? (total > 0 && read >= total ? now : null);

    final next = BookReadingProgress(
      bookId: bookId,
      scriptureId: scriptureId ?? prev?.scriptureId,
      lastSectionIdx: sectionIndex,
      sectionsTotal: total,
      sectionsRead: read,
      lastReadAt: now,
      completedAt: completed,
    );
    state = {...state, bookId: next};

    final db = _ref.read(userDatabaseProvider);
    if (db != null) {
      try {
        await db.raw.insert(
          'reading_progress',
          {
            'book_id': bookId,
            'scripture_id': next.scriptureId,
            'last_section_idx': sectionIndex,
            'sections_total': total,
            'sections_read': read,
            'last_read_at': now.millisecondsSinceEpoch,
            'completed_at': completed?.millisecondsSinceEpoch,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        // Feed the shared practice history so reading appears on the Sadhana
        // hub. Only genuinely NEW verses are counted — paging back through
        // something already read would otherwise inflate the day's total.
        final newlyRead = read - prevRead;
        if (newlyRead > 0) {
          await db.raw.insert('sadhana_sessions', {
            'day_stamp': dayStamp(),
            'practice': 'reading',
            'count': newlyRead,
            'duration_s': 0,
            'meta': '{"bookId":$bookId}',
            'created_at': now.millisecondsSinceEpoch,
          });
        }
      } catch (e) {
        debugPrint('ReadingProgressController: record failed ($e)');
      }
    }

    final prefs = _ref.read(sharedPrefsProvider);
    await prefs.setInt('${PrefKeys.scripturePosPrefix}$bookId', sectionIndex);
    if (scriptureId != null) {
      await prefs.setString(
        PrefKeys.scriptureLast,
        jsonEncode({
          'scriptureId': scriptureId,
          'bookId': bookId,
          'index': sectionIndex,
        }),
      );
    }
  }
}

int _readingStreak(Set<String> readDays) {
  if (readDays.isEmpty) return 0;
  var streak = 0;
  var day = DateTime.now();
  // If nothing read today yet, streak still counts from yesterday.
  if (!readDays.contains(dayStampFrom(day))) {
    day = day.subtract(const Duration(days: 1));
  }
  while (readDays.contains(dayStampFrom(day))) {
    streak++;
    day = day.subtract(const Duration(days: 1));
  }
  return streak;
}

String dayStampFrom(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

final readingProgressProvider = StateNotifierProvider<ReadingProgressController,
    Map<int, BookReadingProgress>>((ref) => ReadingProgressController(ref));
