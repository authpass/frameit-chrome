import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as path;

part 'scene.g.dart';

class Assets {
  static Future<void> extractTo(Directory baseDirectory) async {
    for (final asset in _Assets.all) {
      final f = File(path.join(baseDirectory.path, asset.fileName));
      await f.parent.create(recursive: true);
      await f
          .writeAsBytes(BZip2Decoder().decodeBytes(base64.decode(asset.bytes)));
    }
  }
}
