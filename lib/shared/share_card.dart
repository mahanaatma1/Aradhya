import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
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
      child: OverflowBox(
        alignment: Alignment.topLeft,
        minWidth: 0,
        maxWidth: double.infinity,
        minHeight: 0,
        maxHeight: double.infinity,
        child: Material(
          type: MaterialType.transparency,
          child: RepaintBoundary(key: key, child: card),
        ),
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
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(bytes);
      await SharePlus.instance.share(ShareParams(
        files: [XFile(file.path, mimeType: 'image/png')],
        text: text,
      ));
      return;
    }
    await SharePlus.instance.share(ShareParams(text: text));
  } catch (e, st) {
    debugPrint('share failed: $e');
    debugPrintStack(stackTrace: st);
    messenger?.showSnackBar(
      const SnackBar(content: Text('Could not share')),
    );
  }
}

/// Share plain text via the current share_plus API.
Future<void> shareText(String text) =>
    SharePlus.instance.share(ShareParams(text: text));
