import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:frameit_chrome/src/config.dart';
import 'package:frameit_chrome/src/frame_process.dart';
import 'package:frameit_chrome/src/frameit_frame.dart';
import 'package:frameit_chrome/src/scene.dart';
import 'package:logging/logging.dart';
import 'package:logging_appenders/logging_appenders.dart';
import 'package:path/path.dart' as path;
import 'package:quiver/check.dart';
import 'package:yaml/yaml.dart';

final _logger = Logger('frame');

const chromeBinaryMac =
    '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';

const ARG_BASE_DIR = 'base-dir';
const ARG_FRAMES_DIR = 'frames-dir';
const ARG_CHROME_BINARY = 'chrome-binary';
const ARG_PIXEL_RATIO = 'pixel-ratio';

const FRAMES_REPO = 'https://github.com/fastlane/frameit-frames';

Future<void> main(List<String> args) async {
  PrintAppender.setupLogging(stderrLevel: Level.WARNING);

  final parser = ArgParser();
  parser.addOption(ARG_BASE_DIR,
      help: 'base dir of screenshots. (android/fastlane/metadata/android)');
  parser.addOption(ARG_FRAMES_DIR,
      help:
          'dir with frames from $FRAMES_REPO (e.g. checkout/frameit-frames/latest)');
  parser.addOption(ARG_CHROME_BINARY,
      help: 'Path to chrome binary.', defaultsTo: chromeBinaryMac);
  parser.addOption(ARG_PIXEL_RATIO,
      valueHelp: '2',
      help: 'Device pixel to real pixel ratio.',
      defaultsTo: '2');
  final result = parser.parse(args);

  final baseDir = result[ARG_BASE_DIR] as String;
  final framesDir = result[ARG_FRAMES_DIR] as String;
  final chromeBinary = result[ARG_CHROME_BINARY] as String;
  final pixelRatio = double.tryParse(result[ARG_PIXEL_RATIO].toString());
  if (baseDir == null ||
      framesDir == null ||
      chromeBinary == null ||
      pixelRatio == null) {
    print(parser.usage);
    exit(1);
  }
  if (!File(chromeBinary).existsSync()) {
    _logger.severe('Unable to find chrome at $chromeBinary');
    print(parser.usage);
    exit(1);
  }
  try {
    await runFrame(baseDir, framesDir, chromeBinary, pixelRatio);
  } catch (e, stackTrace) {
    _logger.severe('Error while creating frames.', e, stackTrace);
  }
}

final localePattern = RegExp('^[a-z]{2}-[A-Z]{2}');

Future<void> runFrame(String baseDir, String framesDirPath, String chromeBinary,
    double pixelRatio) async {
  // validate folder.
  // find strings files (title.strings and keywords.strings)
  final dir = Directory(baseDir);
  checkArgument(dir.existsSync(), message: 'directory $dir does not exist.');
  final outDir = Directory(path.join(dir.parent.path, 'framed'));
  if (outDir.existsSync()) {
    _logger.info('Deleting output directory $outDir');
    await outDir.delete(recursive: true);
  }
  final config = await FrameConfig.load(baseDir);
  await outDir.create(recursive: true);
  final framesDir = Directory(framesDirPath);
  checkArgument(framesDir.existsSync(),
      message: '$framesDir does not exist (download $FRAMES_REPO).');
  final framesProvider = await FramesProvider.create(framesDir);

  final tempDir = await Directory.systemTemp.createTemp('frameit_chrome');
  _logger.fine('Using ${tempDir.path}');
  await Assets.extractTo(tempDir);

  final frameProcess = FrameProcess(
    config: config,
    chromeBinary: chromeBinary,
    framesProvider: framesProvider,
    pixelRatio: pixelRatio,
    workingDir: Directory(path.join(tempDir.path, 'asset')),
  );

  await for (final localeDir in dir.list()) {
    if (localeDir is! Directory) {
      // _logger.info('not a director ${localeDir}');
      continue;
    }
    if (!localePattern.hasMatch(path.basename(localeDir.path))) {
      _logger.finer('dir is not a locale: ${path.basename(localeDir.path)}');
      continue;
    }

    final titleStrings =
        await _parseStrings(File(path.join(localeDir.path, 'title.strings')));
    final keywordStrings = await _parseStrings(
            File(path.join(localeDir.path, 'keyword.strings'))) ??
        {};

    if (titleStrings == null) {
      _logger.warning('Locale without titles: $localeDir');
      continue;
    }
    _logger.finer('for ${path.basename(localeDir.path)} Found titles: '
        '${const JsonEncoder.withIndent('  ').convert(titleStrings)}');

    final imagesDir = path.join(localeDir.path);
    final imagesOutDir =
        path.join(outDir.path, path.relative(imagesDir, from: dir.path));
    await frameProcess.processScreenshots(
      Directory(imagesDir),
      Directory(imagesOutDir),
      titleStrings,
      keywordStrings,
    );
  }

  _logger.fine('Deleting temp directory.');
  await tempDir.delete(recursive: true);
}

Future<Map<String, String>> _parseStrings(File file) async {
  final strings = <String, String>{};
  if (!file.existsSync()) {
    return null;
  }
  _logger.finest('reading ${file.path}');
  final tmp = await file.readAsString();
  final tmp2 =
      tmp.replaceAll(RegExp(r';$', multiLine: true), '').replaceAll('=', ':');
  final result = loadYaml(tmp2) as Map;
  _logger.fine('got result: $result');
  if (result == null) {
    return null;
  }
  for (final entry in result.entries) {
    strings[entry.key as String] = entry.value as String;
  }
  return strings;
}

// Galaxy S10: 1523x3214
// iPhone XS Max: 1413x2844
