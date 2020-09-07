import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:framechrome/frame_process.dart';
import 'package:framechrome/frameit_frame.dart';
import 'package:logging/logging.dart';
import 'package:logging_appenders/logging_appenders.dart';
import 'package:path/path.dart' as path;
import 'package:quiver/check.dart';
import 'package:yaml/yaml.dart';

final _logger = Logger('frame');

const chromeBinary =
    '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';

const ARG_BASE_DIR = 'base-dir';
const ARG_FRAMES_DIR = 'frames-dir';

Future<void> main(List<String> args) async {
  PrintAppender.setupLogging(stderrLevel: Level.WARNING);
  final parser = ArgParser();
  parser.addOption(ARG_BASE_DIR,
      help: 'base dir of screenshots. (android/fastlane/metadata/android)');
  parser.addOption(ARG_FRAMES_DIR,
      help:
          'dir with frames from https://github.com/fastlane/frameit-frames (e.g. checkout/frameit-frames/latest)');
  final result = parser.parse(args);

  final baseDir = result[ARG_BASE_DIR] as String;
  final framesDir = result[ARG_FRAMES_DIR] as String;
  if (baseDir == null || framesDir == null) {
    print(parser.usage);
    exit(1);
  }
  await runFrame(baseDir, framesDir);
}

final localePattern = RegExp('^[a-z]{2}-[A-Z]{2}');

Future<void> runFrame(String baseDir, String framesDirPath) async {
  // validate folder.
  // find strings files (title.strings and keywords.strings)
  final dir = Directory(baseDir);
  checkArgument(dir.existsSync(), message: 'directory $dir does not exist.');
  final outDir = Directory(path.join(dir.parent.path, 'framed'));
  if (outDir.existsSync()) {
    _logger.info('Deleting output directory $outDir');
    await outDir.delete(recursive: true);
  }
  await outDir.create(recursive: true);
  final framesDir = Directory(framesDirPath);
  checkArgument(framesDir.existsSync(), message: '$framesDir does not exist.');
  final framesProvider = await FramesProvider.create(framesDir);

  final frameProcess = FrameProcess(
    chromeBinary: chromeBinary,
    framesProvider: framesProvider,
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
            File(path.join(localeDir.path, 'keywords.strings'))) ??
        {};

    if (titleStrings == null) {
      _logger.warning('Locale without titles: $localeDir');
      continue;
    }
    _logger.finer('for ${path.basename(localeDir.path)} Found titles: '
        '${const JsonEncoder.withIndent('  ').convert(titleStrings)}');

    final imagesDir = path.join(localeDir.path, 'images');
    final imagesOutDir =
        path.join(outDir.path, path.relative(imagesDir, from: dir.path));
    await frameProcess.processScreenshots(
      Directory(imagesDir),
      Directory(imagesOutDir),
      titleStrings,
      keywordStrings,
    );
  }
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
