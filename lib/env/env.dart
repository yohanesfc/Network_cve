import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env', obfuscate: true)
abstract class Env {
  @EnviedField(varName: 'NVD_API_KEY')
  static final String nvdApiKey = _Env.nvdApiKey;
}
