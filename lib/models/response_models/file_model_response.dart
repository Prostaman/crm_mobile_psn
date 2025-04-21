import 'package:dart_json_mapper/dart_json_mapper.dart';

import 'package:psn.hotels.hub/models/response_models/base_model_response.dart';

enum FileModelType { Image, Video}

@jsonSerializable
class FileResponse extends BaseModelResponse {
  late FileModelResponse? item;

   FileResponse();

   FileResponse.fromJson(Map<String, dynamic> json) : super.fromJson(json){
    item = (json['item'] != null ? new FileModelResponse.fromJson(json['item']) : null);
  }
}

@jsonSerializable
class FileModelResponse {
  late int id;
  late String url; 

FileModelResponse();

   FileModelResponse.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    url = json['url'];
  }

}


