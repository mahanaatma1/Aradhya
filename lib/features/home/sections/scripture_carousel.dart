import 'package:flutter/material.dart';
import '../../../app/theme/app_theme.dart';

/// A scripture row card: the illustration sits on the left, framed by the
/// signature dashed "stitched" border on its outer edge, with the title and a
/// one-line description on the right.
/// One scripture's carousel-card content — a plain data holder so
/// [ScriptureCarousel] can lay all three out identically.
class ScriptureSpec {
  final String title;
  final String kicker;
  final String subtitle;
  final String? image;
  final Color color;
  final VoidCallback onTap;
  const ScriptureSpec({
    required this.title,
    required this.kicker,
    required this.subtitle,
    this.image,
    required this.color,
    required this.onTap,
  });
}

/// The app's three headline scriptures as a swipeable, full-bleed carousel
/// with a dot pager — replaces three stacked list rows, which buried Ramayana
/// and Upanishads below the fold and gave none of the three room to feel like
/// the centrepiece texts they are.
class ScriptureCarousel extends StatefulWidget {
  final bool hi;
  final List<ScriptureSpec> scriptures;
  const ScriptureCarousel({super.key, required this.hi, required this.scriptures});

  @override
  State<ScriptureCarousel> createState() => _ScriptureCarouselState();
}

class _ScriptureCarouselState extends State<ScriptureCarousel> {
  late final PageController _controller =
      PageController(viewportFraction: 0.82);
  double _page = 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() => _page = _controller.page ?? 0);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 190,
          child: PageView.builder(
            controller: _controller,
            padEnds: false,
            itemCount: widget.scriptures.length,
            itemBuilder: (context, i) {
              final s = widget.scriptures[i];
              return Padding(
                padding: EdgeInsets.only(
                  left: i == 0 ? 16 : 8,
                  right: i == widget.scriptures.length - 1 ? 16 : 8,
                ),
                child: ScriptureSlide(spec: s),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.scriptures.length, (i) {
            final active = (_page.round() == i);
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: active
                    ? widget.scriptures[i].color
                    : widget.scriptures[i].color.withValues(alpha: 0.28),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class ScriptureSlide extends StatelessWidget {
  final ScriptureSpec spec;
  const ScriptureSlide({super.key, required this.spec});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: spec.onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: spec.color,
            image: spec.image == null
                ? null
                : DecorationImage(
                    image: AssetImage(spec.image!),
                    fit: BoxFit.cover,
                    onError: (_, _) {},
                  ),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0),
                  Colors.black.withValues(alpha: 0.15),
                  Colors.black.withValues(alpha: 0.82),
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
            padding: const EdgeInsets.all(16),
            alignment: Alignment.bottomLeft,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(spec.kicker.toUpperCase(),
                    style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w800,
                        color: Colors.white.withValues(alpha: 0.85))),
                const SizedBox(height: 4),
                Text(spec.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontFamily: AppFonts.display,
                        fontWeight: FontWeight.w700,
                        fontSize: 21,
                        color: Colors.white)),
                const SizedBox(height: 4),
                Text(spec.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 12,
                        height: 1.3,
                        color: Colors.white.withValues(alpha: 0.85))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
