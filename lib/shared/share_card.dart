import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Renders [card] off-screen, captures it to a PNG and opens the share sheet
/// with [text] as the caption. If the capture fails for any reason, it falls
/// back to sharing [text] on its own — so Share never leaves the user with an
/// error. Uses the current `SharePlus.instance` API.
Future<void> shareCardImage({
  required BuildContext context,
  required Widget card,
  required String text,
  required String filename,
}) async {
  Uint8List? bytes;
  final overlay = Overlay.of(context);
  final key = GlobalKey();
  final entry = OverlayEntry(
    builder: (_) => Positioned(
      left: -4000,
      top: 0,
      child: Material(
        type: MaterialType.transparency,
        child: RepaintBoundary(key: key, child: card),
      ),
    ),
  );
  overlay.insert(entry);
  try {
    await Future.delayed(const Duration(milliseconds: 80));
    final ctx = key.currentContext;
    if (ctx != null) {
      // ignore: use_build_context_synchronously
      final boundary = ctx.findRenderObject() as RenderRepaintBoundary;
      if (boundary.debugNeedsPaint) {
        await Future.delayed(const Duration(milliseconds: 80));
      }
      final image = await boundary.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      bytes = data?.buffer.asUint8List();
    }
  } catch (_) {
    bytes = null; // fall back to text-only share below
  } finally {
    entry.remove();
  }

  if (bytes != null) {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes);
    await SharePlus.instance
        .share(ShareParams(files: [XFile(file.path)], text: text));
  } else {
    await SharePlus.instance.share(ShareParams(text: text));
  }
}

/// Share plain text via the current share_plus API.
Future<void> shareText(String text) =>
    SharePlus.instance.share(ShareParams(text: text));
