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
    duplicate: json['duplicate'] as bool,
  );
}

Map<String, dynamic> _$FileNameMappingToJson(FileNameMapping instance) =>
    <String, dynamic>{
      'pattern': instance.pattern,
      'replace': instance.replace,
      'duplicate': instance.duplicate,
    };

FrameImage _$FrameImageFromJson(Map json) {
  return FrameImage(
    cropWidth: json['cropWidth'] as int,
    cropHeight: json['cropHeight'] as int,
    device: json['device'] as String,
  );
}

Map<String, dynamic> _$FrameImageToJson(FrameImage instance) =>
    <String, dynamic>{
      'cropWidth': instance.cropWidth,
      'cropHeight': instance.cropHeight,
      'device': instance.device,
    };
