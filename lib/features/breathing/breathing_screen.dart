import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';
import '../../core/providers/app_providers.dart';
import '../../core/user/streak.dart';
import '../../core/user/tts_voice.dart';
import '../../core/user/user_prefs.dart';
import '../../shared/currency_icons.dart';

/// A breathing phase with its duration in seconds.
class BreathPhase {
  final String en;
  final String hi;
  final int seconds;
  const BreathPhase(this.en, this.hi, this.seconds);
}

/// A named pranayama pattern (a repeating cycle of phases) + a one-line benefit.
class BreathPattern {
  final String nameEn;
  final String nameHi;
  final String benefitEn;
  final String benefitHi;
  final List<BreathPhase> phases;
  const BreathPattern(
      this.nameEn, this.nameHi, this.benefitEn, this.benefitHi, this.phases);
}

const _patterns = <BreathPattern>[
  BreathPattern('Calm (4-4-4-4)', 'शांति (4-4-4-4)', 'balance & relaxation',
      'संतुलन और विश्राम', [
    BreathPhase('Breathe in', 'श्वास लें', 4),
    BreathPhase('Hold', 'रोकें', 4),
    BreathPhase('Breathe out', 'श्वास छोड़ें', 4),
    BreathPhase('Hold', 'रोकें', 4),
  ]),
  BreathPattern('Relax (4-7-8)', 'विश्राम (4-7-8)', 'eases stress, helps sleep',
      'तनाव कम करे, नींद में मदद', [
    BreathPhase('Breathe in', 'श्वास लें', 4),
    BreathPhase('Hold', 'रोकें', 7),
    BreathPhase('Breathe out', 'श्वास छोड़ें', 8),
  ]),
  BreathPattern('Deep (6-6)', 'गहरी (6-6)', 'steady focus', 'स्थिर एकाग्रता', [
    BreathPhase('Breathe in', 'श्वास लें', 6),
    BreathPhase('Breathe out', 'श्वास छोड़ें', 6),
  ]),
];

const _roundOptions = [3, 5, 7, 10];

/// Guided breathing — an expanding/contracting orb paces each phase, a 1-second
/// timer owns the phase timing. Features: pattern presets + a custom rhythm,
/// a rounds target, voice cues (TTS) + haptics, pause/resume, a phase-shifting
/// ambient background, screen-awake during a session, a Kamal reward and a
/// daily breathing streak.
class BreathingScreen extends ConsumerStatefulWidget {
  const BreathingScreen({super.key});

  @override
  ConsumerState<BreathingScreen> createState() => _BreathingScreenState();
}

class _BreathingScreenState extends ConsumerState<BreathingScreen>
    with SingleTickerProviderStateMixin {
  static const _minScale = 0.5;
  static const _maxScale = 1.0;

  late final AnimationController _c;
  Timer? _timer;
  Timer? _leadTimer; // the gap after the spoken word, before counting starts
  bool _counting = false; // true once the paced countdown is running
  final FlutterTts _tts = FlutterTts();
  bool _sound = true;

  int _patternIdx = 0; // 0..2 presets, 3 = custom
  int _phaseIdx = 0;
  int _rounds = 0;
  int _remain = 0;
  int _target = 5;
  int _reward = 0;
  int _streak = 0;
  bool _running = false;
  bool _paused = false;
  bool _preparing = false; // speaking the intro before the first phase
  bool _done = false;

  // Custom rhythm (inhale · hold · exhale · hold); a 0 hold is skipped.
  int _cIn = 4, _cHold1 = 4, _cOut = 4, _cHold2 = 4;

  double _fromScale = _minScale;
  double _toScale = _minScale;

  BreathPattern get _customPattern => BreathPattern(
        'Custom', 'अनुकूलित', 'your own rhythm', 'आपकी अपनी लय',
        [
          BreathPhase('Breathe in', 'श्वास लें', _cIn),
          if (_cHold1 > 0) BreathPhase('Hold', 'रोकें', _cHold1),
          BreathPhase('Breathe out', 'श्वास छोड़ें', _cOut),
          if (_cHold2 > 0) BreathPhase('Hold', 'रोकें', _cHold2),
        ],
      );
  List<BreathPattern> get _allPatterns => [..._patterns, _customPattern];
  BreathPattern get _pattern => _allPatterns[_patternIdx];
  BreathPhase get _phase => _pattern.phases[_phaseIdx];
  bool get _isCustom => _patternIdx == _patterns.length;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this);
    _tts
      ..awaitSpeakCompletion(false)
      ..setSpeechRate(0.42);
    _loadStreak();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _leadTimer?.cancel();
    _tts.stop();
    WakelockPlus.disable();
    _c.dispose();
    super.dispose();
  }

  // ---- streak ----------------------------------------------------------------

  void _loadStreak() {
    final p = ref.read(sharedPrefsProvider);
    _streak = p.getInt(PrefKeys.breathStreak) ?? 0;
    final last = p.getString(PrefKeys.breathLast) ?? '';
    if (last.isNotEmpty) {
      final gap = dayGap(last, dayStamp());
      if (gap != null && gap > 1) _streak = 0; // lapsed
    }
  }

  void _bumpStreak() {
    final p = ref.read(sharedPrefsProvider);
    final last = p.getString(PrefKeys.breathLast) ?? '';
    final today = dayStamp();
    if (last == today) return; // already counted today
    final gap = dayGap(last, today);
    final days = (gap == 1) ? _streak + 1 : 1;
    p.setString(PrefKeys.breathLast, today);
    p.setInt(PrefKeys.breathStreak, days);
    _streak = days;
  }

  // ---- session control -------------------------------------------------------

  void _start() {
    WakelockPlus.enable();
    setState(() {
      _running = true;
      _paused = false;
      _done = false;
      _preparing = false;
      _phaseIdx = 0;
      _rounds = 0;
    });
    if (_sound) {
      // Speak a short how-to, then begin the first phase when it finishes.
      final hi = ref.read(isHindiProvider);
      setState(() => _preparing = true);
      _applyVoice(hi);
      _tts.setCompletionHandler(() {
        _tts.setCompletionHandler(() {});
        if (mounted && _running && _preparing) _beginSession();
      });
      _tts.speak(hi
          ? 'आइए शुरू करें। मेरी आवाज़ के साथ चलें — गिनती के साथ श्वास लें, फिर रोकें, फिर श्वास छोड़ें।'
          : "Let's begin. Follow my voice — breathe in as I count, then hold, then breathe out.");
      // Safety net if the completion callback never fires.
      Future.delayed(const Duration(seconds: 9), () {
        if (mounted && _running && _preparing) _beginSession();
      });
    } else {
      _beginSession();
    }
  }

  void _beginSession() {
    setState(() => _preparing = false);
    _beginPhase(); // schedules the lead → _runPhase (which starts the timer)
  }

  void _say(String s) {
    if (!_sound) return;
    _applyVoice(ref.read(isHindiProvider));
    _tts.speak(s);
  }

  void _applyVoice(bool hi) =>
      applyTtsVoice(_tts, ref.read(sharedPrefsProvider), hi);

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _pause() {
    _paused = true;
    _timer?.cancel();
    _leadTimer?.cancel();
    _tts.stop();
    _c.stop();
    setState(() {});
  }

  void _resume() {
    _paused = false;
    setState(() {});
    if (_counting) {
      _c.forward(from: _c.value);
      _startTimer();
    } else {
      _beginPhase(); // was mid-word — replay the phase intro
    }
  }

  void _stop() {
    _running = false;
    _paused = false;
    _preparing = false;
    _counting = false;
    _timer?.cancel();
    _leadTimer?.cancel();
    _tts.stop();
    WakelockPlus.disable();
    _c.stop();
    _c.value = 0;
    setState(() {
      _fromScale = _minScale;
      _toScale = _minScale;
      _remain = 0;
    });
  }

  void _finish() {
    _running = false;
    _paused = false;
    _counting = false;
    _timer?.cancel();
    _leadTimer?.cancel();
    _tts.stop();
    WakelockPlus.disable();
    _c.stop();
    _c.value = 0;
    HapticFeedback.mediumImpact();
    final reward = (_target / 2).round().clamp(2, 6);
    ref.read(streakProvider.notifier).earn(reward);
    _bumpStreak();
    setState(() {
      _done = true;
      _reward = reward;
      _fromScale = _minScale;
      _toScale = _minScale;
      _remain = 0;
    });
  }

  void _selectPattern(int i) {
    _stop();
    setState(() {
      _patternIdx = i;
      _phaseIdx = 0;
      _done = false;
    });
  }

  void _beginPhase() {
    final label = _phase.en;
    if (label == 'Breathe in') {
      _fromScale = _minScale;
      _toScale = _maxScale;
    } else if (label == 'Breathe out') {
      _fromScale = _maxScale;
      _toScale = _minScale;
    } else {
      _fromScale = _toScale; // Hold
    }
    _remain = _phase.seconds;
    _counting = false;
    _timer?.cancel();
    _c.stop();
    _c.value = 0; // orb rests at the start size while the word is spoken
    _cuePhase(); // haptic + speak the phase word ("Breathe in" …)
    setState(() {});
    // Give the spoken word a moment, THEN start the paced count + orb.
    _leadTimer?.cancel();
    _leadTimer = Timer(const Duration(milliseconds: 1000), _runPhase);
  }

  void _runPhase() {
    if (!_running || _paused) return;
    _counting = true;
    _c.duration = Duration(seconds: _phase.seconds);
    _c.forward(from: 0);
    _say('1'); // count "1" as the breath begins
    _startTimer();
    setState(() {});
  }

  void _tick() {
    if (!_running || _paused) return;
    if (_remain > 1) {
      setState(() => _remain--);
      // Count the seconds aloud: "breathe in … 2, 3, 4" (the label is beat 1).
      _say('${_phase.seconds - _remain + 1}');
      return;
    }
    final next = (_phaseIdx + 1) % _pattern.phases.length;
    if (next == 0) {
      final done = _rounds + 1;
      setState(() {
        _phaseIdx = 0;
        _rounds = done;
      });
      if (done >= _target) {
        _finish();
        return;
      }
    } else {
      setState(() => _phaseIdx = next);
    }
    _beginPhase();
  }

  void _cuePhase() {
    switch (_phase.en) {
      case 'Breathe in':
      case 'Breathe out':
        HapticFeedback.lightImpact();
        break;
      default:
        HapticFeedback.selectionClick();
    }
    if (_sound) {
      final hi = ref.read(isHindiProvider);
      _tts.stop();
      _applyVoice(hi);
      _tts.speak(hi ? _phase.hi : _phase.en);
    }
  }

  Color _phaseColor() {
    if (!_running) return AppColors.terracotta;
    switch (_phase.en) {
      case 'Breathe in':
        return const Color(0xFF3E8E7E);
      case 'Breathe out':
        return AppColors.terracotta;
      default:
        return AppColors.gold;
    }
  }

  // ---- sheets ----------------------------------------------------------------

  void _showInstructions(bool hi) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        Widget bullet(String t) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('•  ',
                      style: TextStyle(color: scheme.primary, height: 1.4)),
                  Expanded(
                      child: Text(t,
                          style: const TextStyle(fontSize: 14.5, height: 1.4))),
                ],
              ),
            );
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(hi ? 'कैसे करें' : 'How it works',
                    style: const TextStyle(
                        fontFamily: AppFonts.display,
                        fontWeight: FontWeight.w700,
                        fontSize: 22)),
                const SizedBox(height: 14),
                bullet(hi
                    ? 'चमकते वृत्त का अनुसरण करें: बड़ा होने पर श्वास लें, रुकने पर रोकें, छोटा होने पर श्वास छोड़ें।'
                    : 'Follow the glowing circle: breathe IN as it grows, HOLD when it pauses, breathe OUT as it shrinks.'),
                bullet(hi
                    ? 'एक पैटर्न और कितने चक्र चाहिए चुनें, फिर “आरंभ करें” दबाएँ। पूरा होने पर यह अपने आप रुक जाएगा।'
                    : 'Pick a pattern and how many rounds, then tap Begin. It stops on its own when you finish.'),
                bullet(hi
                    ? 'ध्वनि निर्देश और हल्का कंपन हर चरण पर मार्गदर्शन करते हैं — आँखें बंद करके भी करें।'
                    : 'Voice cues and a gentle vibration guide each phase — practise even with eyes closed.'),
                const SizedBox(height: 12),
                Text(hi ? 'पैटर्न' : 'PATTERNS',
                    style: TextStyle(
                        fontSize: 12,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w700,
                        color: scheme.secondary)),
                const SizedBox(height: 8),
                for (final p in _patterns)
                  bullet(
                      '${hi ? p.nameHi : p.nameEn} — ${hi ? p.benefitHi : p.benefitEn}'),
                bullet(hi
                    ? 'अनुकूलित — अपनी श्वास-रोक-श्वास अवधि स्वयं तय करें।'
                    : 'Custom — set your own inhale · hold · exhale seconds.'),
              ],
            ),
          ),
        );
      },
    );
  }

  void _editCustom(bool hi) {
    var vIn = _cIn, vH1 = _cHold1, vOut = _cOut, vH2 = _cHold2;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          Widget row(String label, int val, int min, ValueChanged<int> set) {
            final scheme = Theme.of(ctx).colorScheme;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(
                      child: Text(label,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600))),
                  IconButton.outlined(
                    onPressed: val <= min ? null : () => set(val - 1),
                    icon: const Icon(Icons.remove_rounded),
                  ),
                  SizedBox(
                    width: 46,
                    child: Text('$val',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontFamily: AppFonts.display,
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                            color: scheme.primary)),
                  ),
                  IconButton.outlined(
                    onPressed: val >= 12 ? null : () => set(val + 1),
                    icon: const Icon(Icons.add_rounded),
                  ),
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(hi ? 'अपनी लय बनाएं' : 'Your own rhythm',
                    style: const TextStyle(
                        fontFamily: AppFonts.display,
                        fontWeight: FontWeight.w700,
                        fontSize: 22)),
                const SizedBox(height: 4),
                Text(hi ? 'सेकंड में' : 'in seconds',
                    style: TextStyle(
                        color: Theme.of(ctx)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5))),
                const SizedBox(height: 8),
                row(hi ? 'श्वास लें' : 'Inhale', vIn, 2,
                    (v) => setSheet(() => vIn = v)),
                row(hi ? 'रोकें' : 'Hold', vH1, 0,
                    (v) => setSheet(() => vH1 = v)),
                row(hi ? 'श्वास छोड़ें' : 'Exhale', vOut, 2,
                    (v) => setSheet(() => vOut = v)),
                row(hi ? 'रोकें' : 'Hold', vH2, 0,
                    (v) => setSheet(() => vH2 = v)),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      setState(() {
                        _cIn = vIn;
                        _cHold1 = vH1;
                        _cOut = vOut;
                        _cHold2 = vH2;
                        _patternIdx = _patterns.length; // select custom
                      });
                      Navigator.pop(ctx);
                    },
                    child: Text(hi ? 'सहेजें' : 'Save'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ---- build -----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final hi = ref.watch(isHindiProvider);
    final scheme = Theme.of(context).colorScheme;
    final ambient = (_running ? _phaseColor() : scheme.primary);

    return Scaffold(
      appBar: AppBar(
        title: Text(hi ? 'प्राणायाम' : 'Breathing'),
        actions: [
          if (_streak > 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text('🔥 $_streak',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, color: scheme.secondary)),
              ),
            ),
          IconButton(
            icon: Icon(
                _sound ? Icons.volume_up_rounded : Icons.volume_off_rounded),
            tooltip: hi ? 'ध्वनि निर्देश' : 'Voice cues',
            onPressed: () => setState(() {
              _sound = !_sound;
              if (!_sound) _tts.stop();
            }),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            tooltip: hi ? 'कैसे करें' : 'How it works',
            onPressed: () => _showInstructions(hi),
          ),
        ],
      ),
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 900),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [ambient.withValues(alpha: 0.12), Colors.transparent],
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _allPatterns.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final p = _allPatterns[i];
                  return ChoiceChip(
                    label: Text(hi ? p.nameHi : p.nameEn),
                    selected: i == _patternIdx,
                    onSelected: _running ? null : (_) => _selectPattern(i),
                  );
                },
              ),
            ),
            Expanded(
              child: Center(
                child: _done
                    ? _completion(hi, scheme)
                    : AnimatedBuilder(
                        animation: _c,
                        builder: (context, _) => _orb(hi, scheme),
                      ),
              ),
            ),
            if (!_running && !_done) _readyControls(hi, scheme),
            _buttons(hi),
          ],
        ),
      ),
    );
  }

  Widget _buttons(bool hi) {
    final endBtn = OutlinedButton.icon(
      onPressed: _stop,
      icon: const Icon(Icons.stop_rounded),
      label: Text(hi ? 'समाप्त' : 'End'),
      style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16)),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: !_running
          ? SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _start,
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(_done
                    ? (hi ? 'फिर से करें' : 'Go again')
                    : (hi ? 'आरंभ करें' : 'Begin')),
                style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16)),
              ),
            )
          : _preparing
              ? SizedBox(width: double.infinity, child: endBtn)
              : Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _paused ? _resume : _pause,
                        icon: Icon(_paused
                            ? Icons.play_arrow_rounded
                            : Icons.pause_rounded),
                        label: Text(_paused
                            ? (hi ? 'जारी रखें' : 'Resume')
                            : (hi ? 'ठहरें' : 'Pause')),
                        style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: endBtn),
                  ],
                ),
    );
  }

  Widget _orb(bool hi, ColorScheme scheme) {
    final eased = Curves.easeInOut.transform(_c.value);
    final scale =
        _running ? _fromScale + (_toScale - _fromScale) * eased : _minScale;
    final color = _phaseColor();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 300,
          height: 300,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 296,
                height: 296,
                child: CircularProgressIndicator(
                  value: _running ? _c.value : 0,
                  strokeWidth: 6,
                  backgroundColor: scheme.onSurface.withValues(alpha: 0.07),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
              Transform.scale(
                scale: scale,
                child: Container(
                  width: 230,
                  height: 230,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      Color.lerp(color, Colors.white, 0.35)!,
                      color,
                    ]),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.35),
                        blurRadius: 44,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    !_running
                        ? (hi ? 'तैयार?' : 'Ready?')
                        : _preparing
                            ? (hi ? 'तैयार हो जाइए…' : 'Get ready…')
                            : _paused
                                ? (hi ? 'ठहरा हुआ' : 'Paused')
                                : (hi ? _phase.hi : _phase.en),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontFamily: AppFonts.display,
                        fontWeight: FontWeight.w700,
                        fontSize: 22,
                        color: Colors.white),
                  ),
                  if (_running && !_paused && !_preparing && _counting) ...[
                    const SizedBox(height: 4),
                    // Count up (1,2,3,4) to match the spoken count.
                    Text('${_phase.seconds - _remain + 1}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 30,
                            color: Colors.white)),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 26),
        Text(
          _running
              ? (hi
                  ? 'चक्र ${_rounds + 1} / $_target'
                  : 'Round ${_rounds + 1} of $_target')
              : (hi ? 'वृत्त के साथ साँस लें' : 'Breathe with the circle'),
          style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface.withValues(alpha: 0.6)),
        ),
      ],
    );
  }

  Widget _completion(bool hi, ColorScheme scheme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [
              Color.lerp(AppColors.sacredGreen, Colors.white, 0.4)!,
              AppColors.sacredGreen,
            ]),
            boxShadow: [
              BoxShadow(
                  color: AppColors.sacredGreen.withValues(alpha: 0.3),
                  blurRadius: 40,
                  spreadRadius: 3),
            ],
          ),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 64),
        ),
        const SizedBox(height: 24),
        Text(hi ? 'बहुत बढ़िया!' : 'Well done!',
            style: const TextStyle(
                fontFamily: AppFonts.display,
                fontWeight: FontWeight.w700,
                fontSize: 26)),
        const SizedBox(height: 6),
        Text(
          hi ? '$_target चक्र पूरे हुए' : '$_target rounds complete',
          style: TextStyle(
              fontSize: 15, color: scheme.onSurface.withValues(alpha: 0.6)),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            _pill(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const KamalIcon(size: 16),
                  const SizedBox(width: 6),
                  Text(hi ? '+$_reward कमल' : '+$_reward Kamal',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                          color: Color(0xFF8A6D1E))),
                ],
              ),
              color: AppColors.gold,
            ),
            _pill(
              child: Text(
                  hi ? '🔥 $_streak दिन की श्रृंखला' : '🔥 $_streak-day streak',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                      color: scheme.secondary)),
              color: scheme.secondary,
            ),
          ],
        ),
      ],
    );
  }

  Widget _pill({required Widget child, required Color color}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: child,
      );

  Widget _readyControls(bool hi, ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 4),
      child: Column(
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            children: [
              TextButton.icon(
                onPressed: () => _showInstructions(hi),
                icon: const Icon(Icons.info_outline_rounded, size: 18),
                label: Text(hi ? 'कैसे करें' : 'How it works'),
              ),
              if (_sound)
                TextButton.icon(
                  onPressed: () => showVoicePicker(
                    context: context,
                    tts: _tts,
                    prefs: ref.read(sharedPrefsProvider),
                    hi: hi,
                    previewText: hi
                        ? 'श्वास लें, दो, तीन, चार'
                        : 'Breathe in, two, three, four',
                  ),
                  icon: const Icon(Icons.record_voice_over_rounded, size: 18),
                  label: Text(hi ? 'आवाज़' : 'Voice'),
                ),
              if (_isCustom)
                TextButton.icon(
                  onPressed: () => _editCustom(hi),
                  icon: const Icon(Icons.tune_rounded, size: 18),
                  label: Text(hi ? 'लय बदलें' : 'Edit rhythm'),
                ),
            ],
          ),
          Text(hi ? 'कितने चक्र?' : 'How many rounds?',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface.withValues(alpha: 0.6))),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final r in _roundOptions)
                ChoiceChip(
                  label: Text('$r'),
                  selected: _target == r,
                  onSelected: (_) => setState(() => _target = r),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
