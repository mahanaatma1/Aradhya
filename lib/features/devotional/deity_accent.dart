import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// Maps a deity name to an accent color + icon, so devotional lists get gentle
/// per-deity variety. Our own assignment (not tied to any external app).
class DeityAccent {
  final Color color;
  final IconData icon;
  const DeityAccent(this.color, this.icon);

  static DeityAccent of(String? deity) {
    final d = (deity ?? '').toLowerCase();
    if (d.contains('ganesh')) return const DeityAccent(AppColors.gold, Icons.temple_hindu_rounded);
    if (d.contains('hanuman')) return const DeityAccent(AppColors.terracotta, Icons.bolt_rounded);
    if (d.contains('shiv') || d.contains('shankar') || d.contains('mahadev')) {
      return const DeityAccent(AppColors.dharmaPurple, Icons.self_improvement_rounded);
    }
    if (d.contains('krishn') || d.contains('vishnu') || d.contains('ram')) {
      return const DeityAccent(Color(0xFF3E6DA8), Icons.music_note_rounded);
    }
    if (d.contains('durga') || d.contains('kali') || d.contains('devi') ||
        d.contains('amba') || d.contains('gauri') || d.contains('shakti')) {
      return const DeityAccent(AppColors.deityRose, Icons.local_florist_rounded);
    }
    if (d.contains('lakshmi') || d.contains('laxmi')) {
      return const DeityAccent(Color(0xFFC79A2E), Icons.spa_rounded);
    }
    if (d.contains('saraswati')) return const DeityAccent(AppColors.sacredGreen, Icons.auto_stories_rounded);
    if (d.contains('shani')) return const DeityAccent(Color(0xFF4A4A5A), Icons.dark_mode_rounded);
    return const DeityAccent(AppColors.terracotta, Icons.brightness_7_rounded);
  }
}

/// Collapses a raw deity string ("Lord Shiva (Baidyanath)") into a clean,
/// canonical name for filter chips and grouping.
String canonicalDeity(String? deity) {
  final s = (deity ?? '').toLowerCase();
  if (s.isEmpty) return 'Other';
  const map = {
    'ganesh': 'Ganesha', 'hanuman': 'Hanuman', 'mahadev': 'Shiva',
    'shankar': 'Shiva', 'shiv': 'Shiva', 'krishn': 'Krishna', 'vishnu': 'Vishnu',
    'durga': 'Durga', 'amba': 'Durga', 'gauri': 'Durga', 'kali': 'Kali',
    'lakshmi': 'Lakshmi', 'laxmi': 'Lakshmi', 'saraswati': 'Saraswati',
    'shani': 'Shani', 'ram': 'Rama', 'surya': 'Surya', 'santoshi': 'Santoshi',
    'ganga': 'Ganga', 'tulsi': 'Tulsi', 'kuber': 'Kuber',
  };
  for (final e in map.entries) {
    if (s.contains(e.key)) return e.value;
  }
  // Fallback: first word of the raw string, title-cased.
  final first = deity!.split(RegExp(r'[ (,]')).first;
  return first.isEmpty ? 'Other' : first;
}

/// Hindi label for a canonical deity name (from [canonicalDeity]); falls back
/// to the English name for anything not in the fixed set.
const _deityHi = <String, String>{
  'Ganesha': 'गणेश', 'Hanuman': 'हनुमान', 'Shiva': 'शिव', 'Krishna': 'कृष्ण',
  'Vishnu': 'विष्णु', 'Durga': 'दुर्गा', 'Kali': 'काली', 'Lakshmi': 'लक्ष्मी',
  'Saraswati': 'सरस्वती', 'Shani': 'शनि', 'Rama': 'राम', 'Surya': 'सूर्य',
  'Santoshi': 'संतोषी', 'Ganga': 'गंगा', 'Tulsi': 'तुलसी', 'Kuber': 'कुबेर',
  'Other': 'अन्य',
};

String deityLabel(String canonical, bool hi) =>
    hi ? (_deityHi[canonical] ?? canonical) : canonical;

/// Hindi label for a mantra "type" tag (Chalisa, Aarti, Stotra…); falls back
/// to the original English tag for anything unrecognised.
String mantraTypeLabel(String? typeEn, bool hi) {
  final t = typeEn ?? '';
  if (!hi || t.isEmpty) return t;
  final s = t.toLowerCase();
  const map = <String, String>{
    'chalisa': 'चालीसा', 'aarti': 'आरती', 'arti': 'आरती', 'stotram': 'स्तोत्र',
    'stotra': 'स्तोत्र', 'ashtak': 'अष्टक', 'kavach': 'कवच',
    'sahasranam': 'सहस्रनाम', 'namavali': 'नामावली', 'stuti': 'स्तुति',
    'vandana': 'वंदना', 'amritwani': 'अमृतवाणी', 'bhajan': 'भजन',
    'gayatri': 'गायत्री', 'suktam': 'सूक्तम्', 'mantra': 'मंत्र', 'path': 'पाठ',
  };
  for (final e in map.entries) {
    if (s.contains(e.key)) return e.value;
  }
  return t;
}
