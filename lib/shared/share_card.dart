import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';

/// Renders [card] off-screen, captures it to a PNG and opens the share sheet
/// with [text] as the caption. If the capture fails for any reason, it falls
/// back to sharing [text] on its own -- so Share never leaves the user with an
/// error. Uses the current `SharePlus.instance` API.
///
/// Every share card in the app sets its own width, so the off-screen host only
/// has to stop the screen's height constraint from clipping it. Without that,
/// a card taller than the display captures sheared off at the bottom.
///
/// Failures are reported rather than swallowed. A silent catch here is why a
/// missing platform implementation looked like "the button does nothing".
Future<void> shareCardImage({
  required BuildContext context,
  required Widget card,
  required String text,
  required String filename,
}) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  Uint8List? bytes;
  final overlay = Overlay.of(context, rootOverlay: true);
  final key = GlobalKey();
  final entry = OverlayEntry(
    builder: (_) => Positioned(
      left: -4000,
      top: 0,
      // Unconstrained by the overlay already; an OverflowBox here would make
      // the box infinite and the resulting transform non-finite.
      child: Material(
        type: MaterialType.transparency,
        child: RepaintBoundary(key: key, child: card),
      ),
    ),
  );
  overlay.insert(entry);
  try {
    // Wait for real frames, not a guessed millisecond count.
    RenderRepaintBoundary? boundary;
    for (var i = 0; i < 12; i++) {
      await WidgetsBinding.instance.endOfFrame;
      final object = key.currentContext?.findRenderObject();
      if (object is RenderRepaintBoundary && !object.debugNeedsPaint) {
        boundary = object;
        break;
      }
    }
    if (boundary != null) {
      final image = await boundary.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      bytes = data?.buffer.asUint8List();
    }
  } catch (e) {
    debugPrint('share card capture failed: $e');
    bytes = null; // fall back to text-only share below
  } finally {
    entry.remove();
  }

  try {
    if (bytes != null) {
      // Hand share_plus the bytes, not a path. It writes its own temp file on
      // mobile and reads the bytes directly on web -- so this path no longer
      // needs path_provider, which has no web implementation at all and was
      // throwing MissingPluginException before the share sheet ever opened.
      await SharePlus.instance.share(ShareParams(
        files: [
          XFile.fromData(bytes, name: filename, mimeType: 'image/png'),
        ],
        fileNameOverrides: [filename],
        text: text,
      ));
      return;
    }
    await SharePlus.instance.share(ShareParams(text: text));
  } catch (e, st) {
    debugPrint('share failed: $e');
    debugPrintStack(stackTrace: st);
    // The reason goes on screen, not just in the log. A sideloaded build has
    // no adb attached, and a generic message there is worth nothing.
    messenger?.showSnackBar(SnackBar(
      duration: const Duration(seconds: 8),
      content: Text('Could not share: $e', maxLines: 4),
    ));
  }
}

/// Share plain text via the current share_plus API.
Future<void> shareText(String text) =>
    SharePlus.instance.share(ShareParams(text: text));
