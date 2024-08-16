import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env')
final class Env {
  @EnviedField(varName: 'apiKey')
  static const String apiKey = _Env.apiKey;

  @EnviedField(varName: 'authDomain')
  static const String authDomain = _Env.authDomain;

  @EnviedField(varName: 'databaseURL')
  static const String databaseURL = _Env.databaseURL;

  @EnviedField(varName: 'projectId')
  static const String projectId = _Env.projectId;

  @EnviedField(varName: 'storageBucket')
  static const String storageBucket = _Env.storageBucket;

  @EnviedField(varName: 'messagingSenderId')
  static const String messagingSenderId = _Env.messagingSenderId;

  @EnviedField(varName: 'appId')
  static const String appId = _Env.appId;

  @EnviedField(varName: 'measurementId')
  static const String measurementId = _Env.measurementId;
}
