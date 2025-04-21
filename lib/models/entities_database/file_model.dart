import 'dart:convert';
import 'dart:io';
import 'package:psn.hotels.hub/api/api_container.dart';
import 'package:psn.hotels.hub/models/response_models/base_model.dart';
import 'package:psn.hotels.hub/models/response_models/file_model_response.dart';

class FileModel extends BaseModel {
  int localId = -1;
  int cloudId = 0;
  late String name;
  //late String format;
  late String localPath;
  double? size;
  bool synced = false;
  bool syncError = false;
  String? thumb;
  bool deleted = false;
  num lat = 0.0;
  num long = 0.0;
  String uploadedAt = "";
  String? createdAt;
  int localLocationId = 0;
  int cloudLocationId = 0;

  //for checking editing photo
  bool isEdited = false;
  String oldLocalPath = '';

  dynamic get baseId {
    return localId;
  }

  FileModel();

  FileModelType get type {
    if (name.contains("video")) {
      return FileModelType.Video;
    } else {
      return FileModelType.Image;
    }
  }

  bool get sizeFit {
    if (size != null) {
      if (size! <= ApiEnvironment.getMaxFileSize()) {
        return true;
      }
    }
    return false;
  }

  String get encoded {
    List<int> imageBytes = File(localPath).readAsBytesSync();
    return base64Encode(imageBytes);
  }

  String? get correctSizeMB {
    if (size != null) {
      return (size! / 1024).toStringAsFixed(2) + " MB";
    }
    return null;
  }

  FileModel.fromMap(Map<String, dynamic> map) {
    localId = map['localId'];
    cloudId = map['cloudId'];
    localLocationId = map['localLocationId'];
    cloudLocationId = map['cloudLocationId'];
    name = map['name'];
    //format = map['format'];
    localPath = map['localPath'];
    size = map['size'];
    synced = map['synced'] == 1;
    syncError = map['syncError'] == 1;
    thumb = map['thumb'];
    deleted = map['deleted'] == 1;
    lat = map['lat'];
    long = map['long'];
    uploadedAt = map['uploadedAt'];
    createdAt = map['createdAt'] ?? '2000-01-01T00:00:00';
  }

  Map<String, dynamic> toMap() {
    return {
      'localLocationId': localLocationId,
      'cloudLocationId': cloudLocationId,
      'cloudId': cloudId,
      'name': name,
      //'format': format,
      'localPath': localPath,
      'size': size,
      'synced': synced ? 1 : 0,
      'syncError': syncError ? 1 : 0,
      'thumb': thumb,
      'deleted': deleted ? 1 : 0,
      'lat': lat,
      'long': long,
      'uploadedAt': uploadedAt,
      'createdAt': createdAt ?? '2000-01-01T00:00:00',
    };
  }
}
