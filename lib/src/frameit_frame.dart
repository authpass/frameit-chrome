import 'dart:convert';
import 'dart:io';
import 'package:frameit_chrome/src/frame_colors.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;

import 'package:logging/logging.dart';

final _logger = Logger('frameit_frame');

String _prepareString(String str) =>
    str.replaceAll(RegExp(r'[_-]'), ' ').toLowerCase();

class FramesProvider {
  FramesProvider._(this._frames);

  static final offsetPattern = RegExp(r'^([+-]+\d+)([+-]+\d+)');

  final List<Frame> _frames;

  static MapEntry<String, String> _frameInfo(
      String deviceName, String fileBasename) {
    if (fileBasename.startsWith('Apple ') && !deviceName.startsWith('Apple ')) {
      fileBasename = fileBasename.replaceAll('Apple ', '');
    }
    if (fileBasename.startsWith(deviceName)) {
      if (fileBasename.length > deviceName.length) {
        final color = fileBasename.substring(deviceName.length + 1);
        if (FRAME_COLORS.contains(color)) {
          _logger.finest('Found for $deviceName: $fileBasename');
          return MapEntry(deviceName, color);
        }
      } else {
        return MapEntry(deviceName, null);
      }
    }
    return null;
  }

  static Future<FramesProvider> create(Directory baseDir) async {
    final frameImages = (await baseDir
            .list()
            .where((event) => event.path.endsWith('png'))
            .toList())
        .whereType<File>()
        .toList();

    final offsetsFile = path.join(baseDir.path, 'offsets.json');
    final offsetJson = json.decode(await File(offsetsFile).readAsString())
        as Map<String, Object>;
    final offsets =
        (offsetJson['portrait'] as Map<String, Object>).entries.map((e) {
      final map = e.value as Map<String, Object>;

      final f = frameImages.firstWhere(
          (frame) =>
              _frameInfo(e.key, path.basenameWithoutExtension(frame.path)) !=
              null, orElse: () {
        _logger.warning('Cannot find ${e.key} image.');
        return null;
      });
      if (f == null) {
        return null;
      }
      if (!f.existsSync()) {
        _logger.warning('Unable to find frame image for ${e.key}');
        return null;
      }
      final offsetString = map['offset'] as String;
      final offsetMatch = offsetPattern.firstMatch(offsetString);
      if (offsetMatch == null) {
        throw StateError('Invalid offset: $offsetString');
      }
      // _logger.info('matches:$offsetMatch ${offsetMatch.groupCount}');
      final offsetX = int.parse(offsetMatch.group(1));
      final offsetY = int.parse(offsetMatch.group(2));

      return Frame(
          name: e.key,
          orientation: Orientation.portrait,
          offsetX: offsetX,
          offsetY: offsetY,
          width: int.parse(map['width'].toString()),
          image: f);
    });
    final frames = offsets.where((element) => element != null).toList();
    frames.sort((a, b) => -a.nameMatch.compareTo(b.nameMatch));
    return FramesProvider._(frames);
  }

  Frame frameForScreenshot(String screenshotName) {
    final match = _prepareString(screenshotName);
    return _frames.firstWhere((element) => match.contains(element.nameMatch),
        orElse: () {
      _logger.finest('unable to find frame for $match');
      return null;
    });
  }

// void
}

enum Orientation {
  portrait,
  landscape,
}

class Frame {
  Frame({
    @required this.name,
    @required this.orientation,
    @required this.offsetX,
    @required this.offsetY,
    @required this.width,
    @required this.image,
  }) : nameMatch = _prepareString(name);

  final String name;
  final String nameMatch;
  final Orientation orientation;
  final int offsetX;
  final int offsetY;
  final int width;
  final File image;

  @override
  String toString() {
    return 'Frame{name: $name, orientation: $orientation, offsetX: $offsetX, offsetY: $offsetY, width: $width, image: $image}';
  }
}
