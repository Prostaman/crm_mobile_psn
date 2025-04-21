import 'package:dart_json_mapper/dart_json_mapper.dart';

@jsonSerializable
class BaseModelResponse {
  bool? success;
  List<ErrorResponse> errors = [];

 BaseModelResponse({this.success, List<ErrorResponse>? errors})
      : errors = errors ?? <ErrorResponse>[]; // Initialize errors in the constructor

  BaseModelResponse.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    if (json['errors'] != null) {
      errors = <ErrorResponse>[];
      json['errors'].forEach((v) {
        errors.add(new ErrorResponse.fromJson(v));
      });
    }
  }

}

@jsonSerializable
class ErrorResponse {
  late String message;
  late int code;

  ErrorResponse({this.message = "Empty", this.code =-1});

  ErrorResponse.fromJson(Map<String, dynamic> json){
    message = json['message'];
    code = int.parse(json['code'].toString());
  }
  

}
