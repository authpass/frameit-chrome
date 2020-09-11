import 'dart:async';
import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:meta/meta.dart';
import 'package:recase/recase.dart';
import 'package:source_gen/source_gen.dart';

class AssetBundler extends Generator {
  AssetBundler({@required this.filePattern});

  // final String dartFile;
  final String filePattern;

  @override
  FutureOr<String> generate(LibraryReader library, BuildStep buildStep) async {
    // print('bundle for ${buildStep.inputId.path} ?');
    // if (!buildStep.inputId.path.endsWith(dartFile)) {
    //   return null;
    // }
    // print('looking for $filePattern');
    final ret = StringBuffer('''
    class _Asset {
      const _Asset(this.fileName, this.bytes);
      final String fileName;
      final String bytes;
    }
    
    
    class _Assets {
    ''');

    final assetList = <String>[];
    await for (final asset in buildStep.findAssets(Glob(filePattern))) {
      // print('should bundle ${asset.path}');
      final name = asset.path.camelCase;
      final bytes = await buildStep.readAsBytes(asset);
      final compressed = BZip2Encoder().encode(bytes);
      final base64 = base64Encode(compressed);
      ret.writeln(
          '''static const $name = _Asset('${asset.path}', '$base64');''');
      assetList.add(name);
    }

    ret.writeln('static const all = [${assetList.join(',')}];');

    ret.writeln('}');
    return ret.toString();
  }
}
