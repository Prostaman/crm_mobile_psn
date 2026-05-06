import 'dart:convert';
import 'dart:io';
import 'package:psn.hotels.hub/data/datasources/remote/api/api_container.dart';
import 'package:psn.hotels.hub/data/models/response_models/base_model.dart';
import 'package:psn.hotels.hub/data/models/response_models/file_model_response.dart';

class FileModel extends BaseModel {
  int localId = -1;
  int cloudId = -1;
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
  int localLocationId = -1;
  int cloudLocationId = -1;
  int? hotelId;

  //for checking editing photo
  bool isEdited = false;
  Set<String> oldLocalPaths = {};

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
    hotelId = map['hotelId'];
  }

  Map<String, dynamic> toMap() {
    return {
      'localLocationId': localLocationId,
      'cloudLocationId': cloudLocationId,
      'cloudId': cloudId,
      'hotelId': hotelId,
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

  FileModel copyWith({
    int? localId,
    int? cloudId,
    String? name,
    String? localPath,
    double? size,
    bool? synced,
    bool? syncError,
    String? thumb,
    bool? deleted,
    num? lat,
    num? long,
    String? uploadedAt,
    String? createdAt,
    int? localLocationId,
    int? cloudLocationId,
    int? hotelId,
    bool? isEdited,
    Set<String>? oldLocalPaths,
  }) {
    final model = FileModel();

    model.localId = localId ?? this.localId;
    model.cloudId = cloudId ?? this.cloudId;
    model.name = name ?? this.name;
    model.localPath = localPath ?? this.localPath;
    model.size = size ?? this.size;
    model.synced = synced ?? this.synced;
    model.syncError = syncError ?? this.syncError;
    model.thumb = thumb ?? this.thumb;
    model.deleted = deleted ?? this.deleted;
    model.lat = lat ?? this.lat;
    model.long = long ?? this.long;
    model.uploadedAt = uploadedAt ?? this.uploadedAt;
    model.createdAt = createdAt ?? this.createdAt;
    model.localLocationId = localLocationId ?? this.localLocationId;
    model.cloudLocationId = cloudLocationId ?? this.cloudLocationId;
    model.hotelId = hotelId ?? this.hotelId;
    model.isEdited = isEdited ?? this.isEdited;
    model.oldLocalPaths = oldLocalPaths ?? this.oldLocalPaths;

    return model;
  }
}
