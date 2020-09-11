import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'src/asset_bundler.dart';

extension on BuilderOptions {
  String requireConfig(String name) {
    final ret = config[name] as String;
    if (ret == null) {
      throw StateError(
          'Please specify `filePattern` $config (tried to get $name)');
    }
    return ret;
  }
}

Builder assetBundler(BuilderOptions options) => SharedPartBuilder([
      AssetBundler(
        // dartFile: options.requireConfig('dartFile'),
        filePattern: options.requireConfig('filePattern'),
      ),
    ], 'assetBundler');
