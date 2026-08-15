import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';
import '../../core/notifications/reminder_tile.dart';
import '../../core/providers/app_providers.dart';
import '../../core/user/streak.dart';
import '../../shared/currency_icons.dart';
import '../../shared/reference_art.dart';
import 'mandir_models.dart';
import 'mandir_providers.dart';

/// The home shrine.
///
/// This is where Kamal finally has somewhere to go. Offerings are **free**
/// inside the traditional morning and evening windows and cost Kamal outside
/// them — the currency paces the rhythm rather than charging for devotion.
class MandirScreen extends ConsumerStatefulWidget {
  const MandirScreen({super.key});

  @override
  ConsumerState<MandirScreen> createState() => _MandirScreenState();
}

class _MandirScreenState extends ConsumerState<MandirScreen>
    with TickerProviderStateMixin {
  late final AnimationController _flame = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat(reverse: true);

  /// Drives the "rises onto the idol" animation for the last offering.
  late final AnimationController _offer = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  Offering? _flying;

  @override
  void dispose() {
    _flame.dispose();
    _offer.dispose();
    super.dispose();
  }

  Future<void> _offerItem(Offering o) async {
    final hi = ref.read(isHindiProvider);
    final result = await makeOffering(ref, o);
    if (!mounted) return;

    switch (result) {
      case OfferingResult.offered:
        setState(() => _flying = o);
        _offer.forward(from: 0).then((_) {
          if (mounted) setState(() => _flying = null);
        });
      case OfferingResult.notEnoughKamal:
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(hi
              ? 'पर्याप्त कमल नहीं — या प्रातः/सांध्य समय में निःशुल्क अर्पण करें।'
              : 'Not enough Kamal — or offer free during the morning or evening window.'),
        ));
      case OfferingResult.failed:
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(hi ? 'अर्पण दर्ज नहीं हुआ' : 'Could not record the offering'),
        ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final hi = ref.watch(isHindiProvider);
    final deity = ref.watch(ishtaDeityProvider);
    final streak = ref.watch(streakProvider);
    final today = ref.watch(todaysOfferingsProvider).valueOrNull ?? const {};
    final offeringStreak = ref.watch(offeringStreakProvider).valueOrNull ?? 0;
    final free = MandirWindows.isFree();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2A1206), Color(0xFF6E1F10), Color(0xFF3A1608)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _TopBar(hindi: hi, kamal: streak.kamal, streak: offeringStreak),
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    _Halo(controller: _flame),
                    _Idol(deity: deity, controller: _flame),
                    if (_flying != null)
                      _FlyingOffering(offering: _flying!, controller: _offer),
                    Positioned(
                      bottom: 6,
                      left: 20,
                      right: 20,
                      child: _WindowNotice(hindi: hi, free: free),
                    ),
                  ],
                ),
              ),
              _OfferingBar(
                hindi: hi,
                free: free,
                today: today,
                onOffer: _offerItem,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: ReminderTile(
                  kind: 'mandir',
                  labelEn: 'Remind me to offer',
                  labelHi: 'अर्पण का स्मरण',
                  titleEn: 'Mandir',
                  titleHi: 'मंदिर',
                  bodyEn: 'The offering window is open.',
                  bodyHi: 'अर्पण का समय खुला है।',
                  // Start of the evening window.
                  defaultMinuteOfDay: 18 * 60,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final bool hindi;
  final int kamal;
  final int streak;
  const _TopBar(
      {required this.hindi, required this.kamal, required this.streak});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 14, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Color(0xFFFCEFE2), size: 19),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          Text(
            hindi ? 'मंदिर' : 'Mandir',
            style: const TextStyle(
              fontFamily: AppFonts.display,
              fontWeight: FontWeight.w700,
              fontSize: 21,
              color: Color(0xFFFCEFE2),
            ),
          ),
          const Spacer(),
          if (streak > 1)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Row(
                children: [
                  const Icon(Icons.local_fire_department_rounded,
                      size: 15, color: Color(0xFFE6C34A)),
                  Text('$streak',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFE6C34A))),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const KamalIcon(size: 14),
                const SizedBox(width: 5),
                Text('$kamal',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFFCEFE2))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A slow breathing glow behind the idol — lamplight, not a loading spinner.
class _Halo extends StatelessWidget {
  final AnimationController controller;
  const _Halo({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, _) {
        final t = 0.82 + 0.18 * controller.value;
        return Container(
          width: 300 * t,
          height: 300 * t,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                const Color(0xFFE6C34A).withValues(alpha: 0.26 * t),
                const Color(0xFFE6C34A).withValues(alpha: 0.0),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Idol extends StatelessWidget {
  final String deity;
  final AnimationController controller;
  const _Idol({required this.deity, required this.controller});

  @override
  Widget build(BuildContext context) {
    final img = deityImage(deity);

    return Padding(
      padding: const EdgeInsets.only(bottom: 30),
      child: img == null
          // No art for this deity yet: a drawn shrine niche rather than a
          // broken-image box.
          ? SizedBox(
              width: 190,
              height: 240,
              child: CustomPaint(painter: _NichePainter()),
            )
          : Image.asset(
              img,
              height: 300,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => SizedBox(
                width: 190,
                height: 240,
                child: CustomPaint(painter: _NichePainter()),
              ),
            ),
    );
  }
}

class _NichePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gold = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xFFE6C34A).withValues(alpha: 0.75);

    final w = size.width, h = size.height;
    // An arched temple niche.
    final path = Path()
      ..moveTo(w * 0.1, h)
      ..lineTo(w * 0.1, h * 0.42)
      ..arcToPoint(Offset(w * 0.9, h * 0.42),
          radius: Radius.circular(w * 0.4))
      ..lineTo(w * 0.9, h);
    canvas.drawPath(path, gold);

    // A lamp flame at the centre.
    final c = Offset(w / 2, h * 0.66);
    canvas.drawCircle(c, 9, Paint()..color = const Color(0xFFE6C34A));
    canvas.drawCircle(
        c.translate(0, -12), 5, Paint()..color = const Color(0xFFFFF3D0));
  }

  @override
  bool shouldRepaint(_NichePainter old) => false;
}

/// The offering rising toward the idol after it is given.
class _FlyingOffering extends StatelessWidget {
  final Offering offering;
  final AnimationController controller;
  const _FlyingOffering(
      {required this.offering, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, _) {
        final t = Curves.easeOutCubic.transform(controller.value);
        return Positioned(
          bottom: 40 + 220 * t,
          child: Opacity(
            opacity: (1 - t).clamp(0.0, 1.0),
            child: Transform.scale(
              scale: 1 + 0.5 * t,
              child: offering.image != null
                  ? Image.asset(offering.image!,
                      height: 46,
                      errorBuilder: (_, _, _) =>
                          Icon(offering.icon, size: 38, color: offering.color))
                  : Icon(offering.icon, size: 38, color: offering.color),
            ),
          ),
        );
      },
    );
  }
}

/// Says plainly whether offerings are free right now, and when they next will
/// be. Telling someone only that they are "too late" is not useful.
class _WindowNotice extends StatelessWidget {
  final bool hindi;
  final bool free;
  const _WindowNotice({required this.hindi, required this.free});

  @override
  Widget build(BuildContext context) {
    final next = MandirWindows.nextOpening();
    final hh = next.hour.toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(free ? Icons.check_circle_rounded : Icons.schedule_rounded,
              size: 15,
              color: free ? const Color(0xFF8FD6A8) : const Color(0xFFE6C34A)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              free
                  ? (hindi
                      ? 'अर्पण का समय खुला है — सब निःशुल्क'
                      : 'The offering window is open — everything is free')
                  : (hindi
                      ? 'अगला निःशुल्क समय $hh:00 बजे'
                      : 'Next free window at $hh:00'),
              style: const TextStyle(
                  fontSize: 12.5, color: Color(0xFFFCEFE2)),
            ),
          ),
        ],
      ),
    );
  }
}

class _OfferingBar extends StatelessWidget {
  final bool hindi;
  final bool free;
  final Map<String, int> today;
  final ValueChanged<Offering> onOffer;

  const _OfferingBar({
    required this.hindi,
    required this.free,
    required this.today,
    required this.onOffer,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      child: Row(
        children: [
          for (final o in kOfferings)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _OfferingButton(
                  offering: o,
                  hindi: hindi,
                  free: free,
                  count: today[o.key] ?? 0,
                  onTap: () => onOffer(o),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _OfferingButton extends StatelessWidget {
  final Offering offering;
  final bool hindi;
  final bool free;
  final int count;
  final VoidCallback onTap;

  const _OfferingButton({
    required this.offering,
    required this.hindi,
    required this.free,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: count > 0 ? 0.18 : 0.09),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: count > 0
                ? const Color(0xFFE6C34A).withValues(alpha: 0.7)
                : Colors.white.withValues(alpha: 0.16),
          ),
        ),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                offering.image != null
                    ? Image.asset(offering.image!,
                        height: 30,
                        errorBuilder: (_, _, _) => Icon(offering.icon,
                            size: 26, color: offering.color))
                    : Icon(offering.icon, size: 26, color: offering.color),
                if (count > 0)
                  Positioned(
                    right: -8,
                    top: -5,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6C34A),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text('$count',
                          style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF3A1608))),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              offering.label(hindi),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFCEFE2)),
            ),
            const SizedBox(height: 2),
            // The price is stated up front, and disappears entirely when the
            // window is open — no surprise deduction.
            free
                ? Text(hindi ? 'निःशुल्क' : 'Free',
                    style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF8FD6A8)))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const KamalIcon(size: 10),
                      const SizedBox(width: 3),
                      Text('${offering.cost}',
                          style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.goldBright)),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}
