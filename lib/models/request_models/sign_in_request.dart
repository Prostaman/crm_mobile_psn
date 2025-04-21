import 'package:dart_json_mapper/dart_json_mapper.dart';

@jsonSerializable
class SignInRequest {
  late String key;
  String login = "";
  String password = "";
}
