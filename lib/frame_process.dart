import 'dart:io';

import 'package:frameit_chrome/frameit_frame.dart';
import 'package:image/image.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:quiver/check.dart';

final _logger = Logger('process_screenshots');

class FrameProcess {
  FrameProcess(
      {@required this.chromeBinary,
      @required this.framesProvider,
      this.pixelRatio});

  final String chromeBinary;
  final FramesProvider framesProvider;
  final double pixelRatio;
  bool validatedPixelRatio = false;

  String rewriteScreenshotName(String name) {
    if (name.contains('framed')) {
      return null;
    }
    return name.replaceAll('samsung-galaxy-s10-plus', 'samsung-galaxy-s10');
  }

  Future<void> processScreenshots(
    Directory dir,
    Directory outDir,
    Map<String, String> titleStrings,
    Map<String, String> keywordStrings,
  ) async {
    checkArgument(dir.existsSync(), message: 'Dir does not exist $dir');
    _logger.info('Processing images in $dir');
    final createdScreenshots = <String>[];
    await for (final fileEntity in dir.list(recursive: true)) {
      if (fileEntity is! File) {
        continue;
      }
      final file = fileEntity as File;

      final image = decodeImage(await file.readAsBytes());

      final name =
          rewriteScreenshotName(path.basenameWithoutExtension(file.path));
      if (name == null) {
        continue;
      }
      final outFilePath =
          path.join(outDir.path, path.relative(file.path, from: dir.path));
      await File(outFilePath).parent.create(recursive: true);

      // final outFile = path.join(file.parent.path,
      //     '{path.basenameWithoutExtension(file.path)}_framed.png');

      // find title and keyword
      final title = _findString(titleStrings, name);
      final keyword = _findString(keywordStrings, name);
      if (title == null) {
        continue;
      }
      final frame = framesProvider.frameForScreenshot(name);
      _logger.fine('Rendering $name with title: $title ($keyword) and $frame');

      final css = await _createCss(
        frame,
        image.width,
        image.height,
        screenshot: file,
        title: title,
        keyword: keyword,
      );
      final indexHtml = File('index.html');
      final cssFile = File('index_override.css');
      final screenshotFile = File('screenshot.png');
      if (screenshotFile.existsSync()) {
        await screenshotFile.delete();
      }
      if (!indexHtml.existsSync()) {
        throw StateError('Expected index.html to be in the current directory.');
      }
      await cssFile.writeAsString(css);
      final runStopwatch = Stopwatch()..start();

      final result = await Process.run(chromeBinary, [
        '--headless',
        '--no-sandbox',
        '--screenshot',
        '--hide-scrollbars',
        '--window-size=${image.width ~/ pixelRatio},${image.height ~/ pixelRatio}',
        'index.html',
      ]);
      if (result.exitCode != 0) {
        throw StateError(
            'Chrome headless did not succeed. ${result.exitCode}: $result');
      }

      if (!validatedPixelRatio) {
        final screenshot = decodeImage(await screenshotFile.readAsBytes());
        if (screenshot.width != image.width) {
          throw StateError(
              'Generated image width did not match original image width. '
              'Wrong device pixel ratio?'
              ' was: ${screenshot.width}'
              ' expected: ${image.width}'
              ' ratio: $pixelRatio');
        }
        validatedPixelRatio = true;
      }
      // final screenshotResized = copyResize(screenshot, width: image.width);
      // await File(outFilePath).writeAsBytes(encodePng(screenshotResized));

      await screenshotFile.copy(outFilePath);

      createdScreenshots.add(outFilePath);

      _logger.info('Created (${runStopwatch.elapsedMilliseconds}ms) '
          '$outFilePath');
    }

    final imageHtml = createdScreenshots.map((e) {
      final src = path.relative(e, from: outDir.path);
      return '''<img src="$src" alt="" />''';
    }).join('');

    await File(path.join(outDir.path, '_present.html')).writeAsString('''
    <html lang="en"><head><title>present me</title>
    <style>
      body { background-color: #efefef; }
      img {
        max-height: 600px;
        margin-left: 16px;
      }
    </style>
    </head>
    $imageHtml
    <body></body></html>
    ''');

    return createdScreenshots;
  }

  static String cssEscape(String str) {
    str = str.replaceAllMapped(RegExp('[^A-Za-z _-]+'), (match) {
      // str.replaceAllMapped(RegExp('[\n\t\'\"]'), (match) {
      final str = match.group(0);
      return str.runes.map((e) {
        return '\\${e.toRadixString(16).padLeft(6, '0')}';
      }).join('');
    });
    return '"$str"';
  }

  Future<String> _createCss(
    Frame frame,
    int targetWidth,
    int targetHeight, {
    @required File screenshot,
    String title,
    String keyword,
  }) async {
    final ratio = pixelRatio;
    final image = decodeImage(await frame.image.readAsBytes());
    final w = image.width / ratio;
    final h = image.height / ratio;
    title ??= '';
    keyword ??= '';
    final separator = title.isNotEmpty && keyword.isNotEmpty ? ' ' : '';
    return '''
:root {
  --frame-orig-width: $w;
  --frame-orig-height: $h;

  --frame-orig-offset-x: ${frame.offsetX / ratio};
  --frame-orig-offset-y: ${frame.offsetY / ratio};

  --target-width: ${targetWidth / ratio};
  --target-height: ${targetHeight / ratio};
}
.keyword:before {
    content: ${cssEscape(keyword)};
}
.keyword:after {
    content: '$separator';
}
.title:after {
    content: ${cssEscape(title)};
}
.screenshot-bg {
    background-image: url("${screenshot.absolute.path}");
}
.frame-bg {
    background-image: url("${frame.image.absolute.path}");
}
''';
  }

  String _findString(Map<String, String> strings, String filename) {
    for (final entry in strings.entries) {
      if (filename.contains(entry.key)) {
        return entry.value;
      }
    }
    return null;
  }
}
