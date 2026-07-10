/// Maps deities / emotions to their bundled illustration assets.
///
/// NOTE: these images currently come from the Ishvarvaani reference set and are
/// PLACEHOLDERS for building the UI at scale. They must be swapped for our own
/// commissioned/licensed art before store submission (see PROGRESS.md gate).
library;

/// Canonical asset stem for a deity name, or null if we have no image.
String? _deityStem(String name) {
  final n = name.toLowerCase();
  if (n.contains('ganesh')) return 'ganesha';
  if (n.contains('krishn')) return 'krishna';
  if (n.contains('shiv') || n.contains('mahadev') || n.contains('shankar')) {
    return 'shiva';
  }
  if (n.contains('durga') || n.contains('devi') || n.contains('amba')) {
    return 'durga';
  }
  if (n.contains('hanuman')) return 'hanuman';
  if (n.contains('lakshmi') || n.contains('laxmi')) return 'lakshmi';
  if (n.contains('kartikeya')) return 'kartikeya';
  if (n.contains('ayyappa')) return 'ayyappa';
  if (n.contains('dattatreya')) return 'dattatreya';
  if (n.contains('meenakshi')) return 'meenakshi';
  if (n.contains('saraswati')) return 'saraswati';
  if (n.contains('ram')) return 'ram';
  return null;
}

/// Full-body deity illustration (transparent background) for the Mandir idol.
String? deityImage(String name) {
  final s = _deityStem(name);
  return s == null ? null : 'assets/images/$s.png';
}

/// Circular deity avatar (the `p…` variant) for pickers and chips.
String? deityAvatar(String name) {
  final s = _deityStem(name);
  return s == null ? null : 'assets/images/p$s.png';
}

/// The 16:9 banner illustration for a Stories emotion, or null.
String? emotionImage(String en) {
  final n = en.toLowerCase();
  const set = {'anger', 'joy', 'peace', 'love', 'fear', 'faith'};
  return set.contains(n) ? 'assets/images/$n.png' : null;
}

/// Scripture scene illustration for a known scripture key.
String? scriptureImage(String key) => switch (key) {
      'gita' => 'assets/images/bhagavadgita.jpg',
      'ramayana' => 'assets/images/ramayana.jpg',
      'upanishads' => 'assets/images/upanishads.jpg',
      'mahabharata' => 'assets/images/mahabharata.jpg',
      _ => null,
    };

/// Home "Spiritual Enlightenment" card art. NOTE: Ishvarvaani placeholders —
/// replace with our own art before store submission (same gate as the rest).
const mantrasImage = 'assets/images/mantras.jpg';
const aartisImage = 'assets/images/aartis.jpg';

/// Full-bleed background art.
const quizBg = 'assets/images/quiz_bg.jpg';

/// Badge art for Home's Engage & Learn tiles.
const quizBadge = 'assets/images/quiz_badge.png';
const japaBadge = 'assets/images/japa_badge.png';
const streakBadge = 'assets/images/streak_badge.png';

/// Offering item art for the Mandir.
const bhogImage = 'assets/images/bhog.png';
const ladooImage = 'assets/images/ladoo.png';
const diyaOnImage = 'assets/images/ondiya.png';
const diyaOffImage = 'assets/images/offdiya.png';
