import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:psn.hotels.hub/models/response_models/base_model_response.dart';
import 'package:psn.hotels.hub/models/response_models/user_model.dart';

@jsonSerializable
class SignInResponse extends BaseModelResponse {
   UserModel? item;

   SignInResponse({this.item, success, errors}) : super();

   SignInResponse.fromJson(Map<String, dynamic> json) : super.fromJson(json){
    item = json['item'] != null ? new UserModel.fromJson(json['item']) : null;
  }

}
