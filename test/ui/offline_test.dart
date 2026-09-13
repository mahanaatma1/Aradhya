import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:divyavaani/core/db/content_database.dart';
import 'package:divyavaani/core/user/tts_voice.dart';

void main() {
  test('gzipInflatedSize reads ISIZE from the trailer', () {
    final raw = List<int>.generate(100000, (i) => i % 251);
    final gz = Uint8List.fromList(gzip.encode(raw));
    expect(ContentDatabase.gzipInflatedSize(gz), raw.length);
  });

  test('InsufficientStorageException reports the shortfall in MB', () {
    const e = InsufficientStorageException(needed: 40 << 20, free: 10 << 20);
    expect(e.shortfallMb, greaterThan(30));
    expect(e.toString(), contains('need 40 MB'));
  });

  test('isOfflineVoice rejects network and uninstalled voices', () {
    expect(isOfflineVoice({'name': 'a', 'locale': 'hi-IN', 'network_required': '0'}), isTrue);
    expect(isOfflineVoice({'name': 'b', 'locale': 'hi-IN', 'network_required': '1'}), isFalse);
    expect(isOfflineVoice({'name': 'c', 'locale': 'hi-IN', 'features': 'notInstalled\tembedded'}), isFalse);
    expect(isOfflineVoice({'name': 'd', 'locale': 'hi-IN'}), isTrue);
  });
}
