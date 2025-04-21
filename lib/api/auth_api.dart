
import 'dart:convert';

import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:dio/dio.dart';
import 'package:psn.hotels.hub/api/base_api.dart';
import 'package:psn.hotels.hub/models/request_models/sign_in_request.dart';
import 'package:psn.hotels.hub/models/response_models/sign_in_response.dart';

class AuthApi extends BaseApi {
  AuthApi() : super();

  Future<SignInResponse?> login(SignInRequest request) async {
    try {
      final parameters = JsonMapper.serialize(request);
      var response = await super.post("login", parameters);

    //JsonDecoder decoder = new JsonDecoder();
    //var deserializedMap = decoder.convert(response.data);
    //var map = json.decode(response.toString());
    //var model = JsonMapper.deserialize<SignInResponse>(response.toString());

       Map<String, dynamic> jsonMap = json.decode(response.toString());
       var model = SignInResponse.fromJson(jsonMap); 
       return model;
    } catch (e) {
      throw e;
    }
  }

  Future<Response> logout() async {
    try {
      return await post("api/user/logout", {});
    } catch (e) {
      throw e;
    }
  }
}
