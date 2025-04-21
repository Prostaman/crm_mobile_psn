import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:psn.hotels.hub/api/base_api.dart';
import 'package:psn.hotels.hub/models/entities_database/file_model.dart';
import 'package:psn.hotels.hub/models/response_models/base_model_response.dart';
import 'package:psn.hotels.hub/models/response_models/file_model_response.dart';

class FilesApi extends BaseApi {
  Future<FileResponse?> send({
    required FileModel file,
    required int hotelId,
  }) async {
    try {
      FormData data = FormData.fromMap({
        "id": file.cloudId,
        "hotelId": hotelId,
        "facilityId": file.cloudLocationId,
        "lat": file.lat,
        "long": file.long,
        "mime": file.type == FileModelType.Image ? "photo" : "video",
        "file": await MultipartFile.fromFile(file.localPath, filename: file.name //, contentType: new MediaType("image", "jpeg")
            )
      });
      var response = await sendFile("addmedia", data);
      debugPrint(response.toString());
      Map<String, dynamic> jsonMap = json.decode(response.toString());
      var model = FileResponse.fromJson(jsonMap);
      return model;
    } catch (e) {
      debugPrint("send file:$e");
      await FirebaseCrashlytics.instance.log("send file:$e, localPath:${file.localPath}");
      await FirebaseCrashlytics.instance.recordFlutterError(FlutterErrorDetails(exception: e));
      return null;
    }
  }

  Future<BaseModelResponse?> deleteFile({required FileModel file}) async {
    try {
      var response = await super.post("deletemedia", {"id": file.cloudId});
      Map<String, dynamic> jsonMap = json.decode(response.toString());
      var model = BaseModelResponse.fromJson(jsonMap);
      return model;
    } catch (e) {
      throw e;
    }
  }

  Future<BaseModelResponse?> changeProfilePhoto({required int cloudId, required bool isHotel}) async {
    try {
      var response = await super.post("UserHotelSetMainMedia", {"id": cloudId, 'ishotel': isHotel});
      Map<String, dynamic> jsonMap = json.decode(response.toString());
      var model = BaseModelResponse.fromJson(jsonMap);
      return model;
    } catch (e) {
      throw e;
    }
  }
}
