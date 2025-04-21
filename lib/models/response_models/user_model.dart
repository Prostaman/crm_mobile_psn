import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:psn.hotels.hub/models/response_models/base_model.dart';

@jsonSerializable
class UserModel extends BaseModel {
  String? token;
  String? userName;

  UserModel({this.token});

   UserModel.fromJson(Map<String, dynamic> json) {
    token = json['token'];
  }
}
