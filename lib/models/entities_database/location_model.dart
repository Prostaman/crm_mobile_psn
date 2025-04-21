import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:psn.hotels.hub/models/response_models/base_model.dart';

class LocationModel extends BaseModel {
  LocationModel();

  LocationModel.params(
      {required this.localId,
      required this.cloudId,
      required this.hotelId,
      required this.name,
      required this.description,
      required this.createdAt,
      required this.synced,
      required this.deleted,
      required this.pathOfProfilePhoto,
      required this.profilePhotoIsChanged,
      required this.idCategory});

  int localId = 0;
  int cloudId = 0;
  int hotelId = -1;
  String name = "";
  String description = "";
  String createdAt = "";
  bool synced = false;
  bool deleted = false;
  String pathOfProfilePhoto = "";
  bool profilePhotoIsChanged = false;
  int idCategory = -1;

  Map<String, dynamic> get toJson {
    return {
      "name": name,
      "description": description,
      "hotelId": hotelId,
      "id": cloudId,
      'categoryId': idCategory
    };
  }

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    try {
      return LocationModel.params(
          localId: json["localId"] ?? -1,
          cloudId: json["id"] ?? 0,
          hotelId: json["hotelId"] ?? -1,
          name: json["name"].toString(),
          description: json["description"].toString(),
          createdAt: json["createdAt"].toString(),
          synced: json["synced"] != null ? json["synced"] : true,
          deleted: json["deleted"] != null ? json["deleted"] : false,
          pathOfProfilePhoto: json["pathOfProfilePhoto"] ?? "",
          profilePhotoIsChanged: json["profilePhotoIsChanged"] != null ? json["profilePhotoIsChanged"] : true,
          idCategory: 9); 
    } catch (e) {
      debugPrint(e.toString());
      FirebaseCrashlytics.instance.log(e.toString());
      FirebaseCrashlytics.instance.recordFlutterError(FlutterErrorDetails(exception: e));
      throw e;
    }
  }

  factory LocationModel.fromMap(Map<String, dynamic> map) {
    return LocationModel.params(
        localId: map["localId"],
        cloudId: map["cloudId"],
        hotelId: map["hotelId"],
        name: map["name"] ?? "",
        description: map["description"] ?? "",
        createdAt: map["createdAt"] ?? "",
        synced: map["synced"] == 1, // Convert integer to boolean
        deleted: map["deleted"] == 1, // Convert integer to boolean
        pathOfProfilePhoto: map["pathOfProfilePhoto"] ?? "",
        profilePhotoIsChanged: map["profilePhotoIsChanged"] == 1,
        idCategory: map['idCategory'] ?? 9);
  }

  Map<String, dynamic> toMap() {
    return {
      'cloudId': cloudId,
      'hotelId': hotelId,
      'name': name,
      'description': description,
      'createdAt': createdAt,
      'synced': synced ? 1 : 0,
      'deleted': deleted ? 1 : 0,
      'pathOfProfilePhoto': pathOfProfilePhoto,
      'profilePhotoIsChanged': profilePhotoIsChanged ? 1 : 0,
      'idCategory': idCategory
    };
  }

}

