import 'dart:io';

import 'package:frameit_chrome/src/config.dart';
import 'package:frameit_chrome/src/frameit_frame.dart';
import 'package:image/image.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:quiver/check.dart';

final _logger = Logger('process_screenshots');

class FrameProcess {
  FrameProcess({
    @required this.workingDir,
    this.config,
    @required this.chromeBinary,
    @required this.framesProvider,
    this.pixelRatio,
  });

  final Directory workingDir;
  final FrameConfig config;
  final String chromeBinary;
  final FramesProvider framesProvider;
  final double pixelRatio;
  bool validatedPixelRatio = false;

  List<String> rewriteScreenshotName(String name) {
    if (name.contains('framed')) {
      return null;
    }
    final rewrite = config?.rewrite;
    if (rewrite == null) {
      return [name];
    }

    final ret = <String>[];
    for (final r in rewrite) {
      final hasMatch = r.patternRegExp.hasMatch(name);
      if (!hasMatch) {
        if (r.action == FileAction.include) {
          return ret;
        }
        continue;
      }
      var newName = name;
      if (r.replace != null) {
        newName = name.replaceAll(r.patternRegExp, r.replace);
      }
      switch (r.action) {
        case FileAction.duplicate:
          ret.add(newName);
          break;
        case FileAction.rename:
          return ret..add(newName);
        case FileAction.exclude:
          return null;
        case FileAction.include:
          break;
      }
    }
    ret.add(name);
    // return name.replaceAll('samsung-galaxy-s10-plus', 'samsung-galaxy-s10');
    return ret;
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

      final name =
          rewriteScreenshotName(path.basenameWithoutExtension(file.path));
      if (name == null) {
        continue;
      }

      for (final variant in name) {
        final outFilePath = await _processScreenshot(
          dir,
          outDir,
          file,
          titleStrings,
          keywordStrings,
          variant,
        );

        if (outFilePath != null) {
          createdScreenshots.add(outFilePath);
        }
      }
    }

    createdScreenshots.sort((a, b) => a.compareTo(b));

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

  Future<String> _processScreenshot(
      Directory srcDir,
      Directory outDir,
      File file,
      Map<String, String> titleStrings,
      Map<String, String> keywordStrings,
      String screenshotName) async {
    // final outFile = path.join(file.parent.path,
    //     '{path.basenameWithoutExtension(file.path)}_framed.png');

    // find title and keyword
    final imageConfig = config.findImageConfig(screenshotName);
    final title = _findString(titleStrings, screenshotName);
    final keyword = _findString(keywordStrings, screenshotName);
    if (title == null) {
      return null;
    }

    final replacedTargetName =
        path.join(file.parent.path, '$screenshotName.png');
    final outFilePath = path.join(
        outDir.path, path.relative(replacedTargetName, from: srcDir.path));
    await File(outFilePath).parent.create(recursive: true);

    final frame = framesProvider
        .frameForScreenshot(imageConfig?.device ?? screenshotName);
    _logger.fine(
        'Rendering $screenshotName with title: $title ($keyword) and $frame');

    final image = decodeImage(await file.readAsBytes());

    final css = await _createCss(
      frame,
      image.width,
      image.height,
      screenshot: file,
      title: title,
      keyword: keyword,
    );
    final indexHtml = File(path.join(workingDir.path, 'index.html'));
    final cssFile = File(path.join(workingDir.path, 'index_override.css'));
    final screenshotFile = File(path.join(workingDir.path, 'screenshot.png'));
    if (screenshotFile.existsSync()) {
      await screenshotFile.delete();
    }
    if (!indexHtml.existsSync()) {
      throw StateError('Expected index.html to be in the current directory.');
    }
    await cssFile.writeAsString(css);
    final runStopwatch = Stopwatch()..start();

    final width = imageConfig?.cropWidth ?? image.width;
    final height = imageConfig?.cropHeight ?? image.height;

    final result = await Process.run(
        chromeBinary,
        [
          '--headless',
          '--no-sandbox',
          '--screenshot',
          '--hide-scrollbars',
          '--window-size=${width ~/ pixelRatio},${height ~/ pixelRatio}',
          'index.html',
        ],
        workingDirectory: workingDir.path);
    if (result.exitCode != 0) {
      throw StateError(
          'Chrome headless did not succeed. ${result.exitCode}: $result');
    }

    if (!validatedPixelRatio) {
      final screenshot = decodeImage(await screenshotFile.readAsBytes());
      if (screenshot.width != width) {
        throw StateError(
            'Generated image width did not match original image width. '
            'Wrong device pixel ratio?'
            ' was: ${screenshot.width}'
            ' expected: $width'
            ' ratio: $pixelRatio');
      }
      validatedPixelRatio = true;
    }
    // final screenshotResized = copyResize(screenshot, width: image.width);
    // await File(outFilePath).writeAsBytes(encodePng(screenshotResized));

    await screenshotFile.copy(outFilePath);

    _logger.info('Created (${runStopwatch.elapsedMilliseconds}ms) '
        '$outFilePath');
    // if (srcDir.path.contains('de-DE') && outFilePath.contains('launchscreen')) {
    //   print('DEBUG me.');
    //   exit(0);
    // }

    return outFilePath;
  }

  static String cssEscape(String str) {
    str = str.replaceAllMapped(RegExp('[^A-Za-z _-]+'), (match) {
      // str.replaceAllMapped(RegExp('[\n\t\'\"]'), (match) {
      final str = match.group(0);
      return str.runes.map((e) {
        return '\\${e.toRadixString(16).padLeft(6, '0')} ';
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
