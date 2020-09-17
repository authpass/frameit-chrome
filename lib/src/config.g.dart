// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FrameConfig _$FrameConfigFromJson(Map json) {
  return FrameConfig(
    rewrite: (json['rewrite'] as List)
        ?.map((e) => e == null ? null : FileNameMapping.fromJson(e as Map))
        ?.toList(),
    images: (json['images'] as Map)?.map(
      (k, e) => MapEntry(
          k as String,
          e == null
              ? null
              : FrameImage.fromJson((e as Map)?.map(
                  (k, e) => MapEntry(k as String, e),
                ))),
    ),
  );
}

Map<String, dynamic> _$FrameConfigToJson(FrameConfig instance) =>
    <String, dynamic>{
      'rewrite': instance.rewrite,
      'images': instance.images,
    };

FileNameMapping _$FileNameMappingFromJson(Map json) {
  return FileNameMapping(
    pattern: json['pattern'] as String,
    replace: json['replace'] as String,
    action: _$enumDecode(_$FileActionEnumMap, json['action']),
  );
}

Map<String, dynamic> _$FileNameMappingToJson(FileNameMapping instance) =>
    <String, dynamic>{
      'pattern': instance.pattern,
      'replace': instance.replace,
      'action': _$FileActionEnumMap[instance.action],
    };

T _$enumDecode<T>(
  Map<T, dynamic> enumValues,
  dynamic source, {
  T unknownValue,
}) {
  if (source == null) {
    throw ArgumentError('A value must be provided. Supported values: '
        '${enumValues.values.join(', ')}');
  }

  final value = enumValues.entries
      .singleWhere((e) => e.value == source, orElse: () => null)
      ?.key;

  if (value == null && unknownValue == null) {
    throw ArgumentError('`$source` is not one of the supported values: '
        '${enumValues.values.join(', ')}');
  }
  return value ?? unknownValue;
}

const _$FileActionEnumMap = {
  FileAction.duplicate: 'duplicate',
  FileAction.exclude: 'exclude',
  FileAction.rename: 'rename',
  FileAction.include: 'include',
};

FrameImage _$FrameImageFromJson(Map json) {
  return FrameImage(
    cropWidth: json['cropWidth'] as int,
    cropHeight: json['cropHeight'] as int,
    device: json['device'] as String,
    previewLabel: json['previewLabel'] as String,
    css: json['css'] as String,
  );
}

Map<String, dynamic> _$FrameImageToJson(FrameImage instance) =>
    <String, dynamic>{
      'cropWidth': instance.cropWidth,
      'cropHeight': instance.cropHeight,
      'device': instance.device,
      'previewLabel': instance.previewLabel,
      'css': instance.css,
    };

// **************************************************************************
// StaticTextGenerator
// **************************************************************************

// ignore_for_file: implicit_dynamic_parameter,strong_mode_implicit_dynamic_parameter,strong_mode_implicit_dynamic_variable,non_constant_identifier_names,unused_element
