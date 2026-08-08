/// A reflection prompt, shipped as content and cited to a verse.
class JournalPrompt {
  final int id;
  final String slug;
  final String promptEn;
  final String? promptHi;
  final String? theme;
  final String? sourceName;
  final String? sourceRef;

  const JournalPrompt({
    required this.id,
    required this.slug,
    required this.promptEn,
    this.promptHi,
    this.theme,
    this.sourceName,
    this.sourceRef,
  });

  factory JournalPrompt.fromRow(Map<String, Object?> r) => JournalPrompt(
        id: r['id'] as int,
        slug: (r['slug'] as String?) ?? '',
        promptEn: (r['prompt_en'] as String?) ?? '',
        promptHi: r['prompt_hi'] as String?,
        theme: r['theme'] as String?,
        sourceName: r['primary_source_name'] as String?,
        sourceRef: r['primary_source_ref'] as String?,
      );

  String prompt(bool hi) =>
      (hi && (promptHi?.isNotEmpty ?? false)) ? promptHi! : promptEn;
}

/// One journal entry. Local only — this never leaves the device.
class JournalEntry {
  final int id;
  final String dayStamp;
  final int? promptId;

  /// A frozen copy of the prompt as it was shown. Prompts live in
  /// `gyan.sqlite` and can change between content builds; an entry must keep
  /// the question it was actually answering.
  final String? promptText;

  final String body;
  final String? mood;
  final String? lesson;
  final DateTime createdAt;
  final DateTime updatedAt;

  const JournalEntry({
    required this.id,
    required this.dayStamp,
    required this.body,
    required this.createdAt,
    required this.updatedAt,
    this.promptId,
    this.promptText,
    this.mood,
    this.lesson,
  });

  factory JournalEntry.fromRow(Map<String, Object?> r) => JournalEntry(
        id: r['id'] as int,
        dayStamp: (r['day_stamp'] as String?) ?? '',
        promptId: r['prompt_id'] as int?,
        promptText: r['prompt_text'] as String?,
        body: (r['body'] as String?) ?? '',
        mood: r['mood'] as String?,
        lesson: r['lesson'] as String?,
        createdAt:
            DateTime.fromMillisecondsSinceEpoch((r['created_at'] as int?) ?? 0),
        updatedAt:
            DateTime.fromMillisecondsSinceEpoch((r['updated_at'] as int?) ?? 0),
      );

  String get excerpt {
    final t = body.replaceAll(RegExp(r'\s+'), ' ').trim();
    return t.length <= 90 ? t : '${t.substring(0, 89)}…';
  }
}

/// Moods, named in Sanskrit rather than as emoji.
///
/// Deliberately not a 1-5 "how was your day" scale: a scale invites a score,
/// and this is a reflection tool, not a mood tracker. These are states the
/// tradition already has words for.
class Moods {
  Moods._();

  static const keys = ['shanti', 'harsha', 'vishada', 'krodha', 'bhaya'];

  static const _en = {
    'shanti': 'Calm',
    'harsha': 'Joy',
    'vishada': 'Heaviness',
    'krodha': 'Anger',
    'bhaya': 'Fear',
  };

  static const _hi = {
    'shanti': 'शांति',
    'harsha': 'हर्ष',
    'vishada': 'विषाद',
    'krodha': 'क्रोध',
    'bhaya': 'भय',
  };

  static String label(String key, bool hi) =>
      (hi ? _hi[key] : _en[key]) ?? key;
}
