import 'dart:io';

import 'package:json_annotation/json_annotation.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

part 'config.g.dart';

@JsonSerializable(anyMap: true)
class FrameConfig {
  FrameConfig({
    @JsonKey(nullable: true) this.rewrite,
    @JsonKey(nullable: true) this.images,
  });
  factory FrameConfig.fromJson(Map json) => _$FrameConfigFromJson(json);

  static const FILE_NAME = 'frameit.yaml';

  Map<String, dynamic> toJson() => _$FrameConfigToJson(this);

  final List<FileNameMapping> rewrite;
  final Map<String, FrameImage> images;

  static Future<FrameConfig> load(String baseDir) async {
    final configFile = File(path.join(baseDir, FrameConfig.FILE_NAME));
    if (!configFile.existsSync()) {
      return null;
    }
    return FrameConfig.fromJson(
        loadYaml(await configFile.readAsString()) as Map);
  }

  FrameImage findImageConfig(String screenshotName) {
    return images.entries
        .firstWhere((element) => screenshotName.contains(element.key),
            orElse: () => null)
        ?.value;
  }
}

enum FileAction {
  duplicate,
  exclude,
  rename,
  include,
}

@JsonSerializable(nullable: false, anyMap: true)
class FileNameMapping {
  FileNameMapping({
    this.pattern,
    this.replace,
    // @JsonKey(defaultValue: false) this.duplicate,
    // @JsonKey(defaultValue: false) this.exclude,
    @JsonKey(defaultValue: FileAction.rename) this.action,
  });
  factory FileNameMapping.fromJson(Map json) => _$FileNameMappingFromJson(json);
  Map<String, dynamic> toJson() => _$FileNameMappingToJson(this);

  final String pattern;
  final String replace;
  // final bool duplicate;
  // final bool exclude;
  final FileAction action;

  RegExp _patternRegExp;
  RegExp get patternRegExp => _patternRegExp ??= RegExp(pattern);
}

@JsonSerializable(nullable: true, anyMap: true)
class FrameImage {
  FrameImage({
    this.cropWidth,
    this.cropHeight,
    this.device,
    this.previewLabel,
    this.css,
  });
  factory FrameImage.fromJson(Map<String, dynamic> json) =>
      _$FrameImageFromJson(json);
  Map<String, dynamic> toJson() => _$FrameImageToJson(this);

  /// Crop with of the final image. (null for using the original width)
  final int cropWidth;

  /// Crop height of the final image. (null for using the original width)
  final int cropHeight;

  /// device name used to look up correct frame.
  final String device;

  /// Optional label used only for the `_preview.html`
  final String previewLabel;

  /// Allows customizing the css.
  final String css;
}
