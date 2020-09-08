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

@JsonSerializable(nullable: false, anyMap: true)
class FileNameMapping {
  FileNameMapping({
    this.pattern,
    this.replace,
    @JsonKey(defaultValue: false) this.duplicate,
  });
  factory FileNameMapping.fromJson(Map json) => _$FileNameMappingFromJson(json);
  Map<String, dynamic> toJson() => _$FileNameMappingToJson(this);

  final String pattern;
  final String replace;
  final bool duplicate;

  RegExp _patternRegExp;
  RegExp get patternRegExp => _patternRegExp ??= RegExp(pattern);
}

@JsonSerializable(nullable: true, anyMap: true)
class FrameImage {
  FrameImage({
    this.cropWidth,
    this.cropHeight,
    this.device,
  });
  factory FrameImage.fromJson(Map<String, dynamic> json) =>
      _$FrameImageFromJson(json);
  Map<String, dynamic> toJson() => _$FrameImageToJson(this);

  final int cropWidth;
  final int cropHeight;
  final String device;
}
