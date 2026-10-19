import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final dir = Directory('assets/images/art');

  test('every picture the screens ask for exists in assets/images/art', () {
    const used = [
      'sili_wave', 'sili_happy', 'sili_think', 'sili_encourage',
      'bunny_happy', 'bunny_think', 'bunny_star',
      'cat_happy', 'bowl', 'apple', 'strawberry', 'star', 'panorama_banner',
    ];
    for (final n in used) {
      expect(File('assets/images/art/$n.png').existsSync(), isTrue, reason: 'missing assets/images/art/$n.png');
    }
  });

  test('art files are PNGs with a real alpha channel (transparent background)', () {
    final files = dir.listSync().whereType<File>().where((f) => f.path.endsWith('.png')).toList();
    expect(files, isNotEmpty);
    for (final f in files) {
      final b = f.readAsBytesSync();
      expect(b.length, greaterThan(33), reason: f.path);
      expect(b.sublist(0, 8), [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A], reason: '${f.path} is not a PNG');
      // IHDR colour type 6 = RGBA, 4 = grey + alpha
      expect([4, 6].contains(b[25]), isTrue, reason: '${f.path} has no alpha channel');
    }
  });
}
