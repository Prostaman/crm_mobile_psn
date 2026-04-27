import 'package:psn.hotels.hub/db/db_manager.dart';
import 'package:psn.hotels.hub/models/entities_database/file_model.dart';
import 'package:psn.hotels.hub/models/entities_database/location_model.dart';
import 'package:psn.hotels.hub/models/response_models/base_model.dart';
import 'package:collection/collection.dart';

class MyHotelModel extends BaseModel {
  late int id;
  String? description;
  late String createdAt;
  late String updatedAt;
  bool synced = true;
  bool deleted = false;
  late String name;
  late String country;
  late String resort;
  String pathOfProfilePhoto = "";
  bool profilePhotoIsChanged = false;

  MyHotelModel();

  Future<List<LocationModel>?> getLocations(DBManager db) async {
    List<Map<String, dynamic>>? locationMaps =
        await (await db.locationsDao()).findLocationsByHotelId(id);
    if (locationMaps != null && locationMaps.isNotEmpty) {
      // Convert each map to a LocationModel object
      List<LocationModel> locations =
          locationMaps.map((map) => LocationModel.fromMap(map)).toList();
      return locations;
    } else {
      return null; // Return null if no locations are found
    }
  }

  Future<int> getLengthOfAllLocationsInTable(DBManager db) async {
    return (await (await db.locationsDao()).getLocationsCount());
  }

  Future<List<FileModel>> getFilesOfMyHotel(DBManager db) async {
    List<FileModel> files = [];
    final locationsData =
        await (await db.locationsDao()).findLocationsByHotelId(id);
    if (locationsData != null && locationsData.isNotEmpty) {
      for (var element in locationsData) {
        final locationModel = LocationModel.fromMap(element);
        final notDeletedFiles = await (await db.filesDao())
                .findNotDeletedFilesByLocationId(locationModel.localId) ??
            [];
        files.addAll(notDeletedFiles);
      }
    }

    return files;
  }

  Future<bool> getLocationSynced(DBManager db) async {
    var x = await (await db.locationsDao()).findLocationsByHotelId(id);
    return x?.firstWhereOrNull(
            (element) => LocationModel.fromMap(element).synced == false) ==
        null;
  }

  Future<double> getPercentLoadedOfAllFilesOfMyHotel(DBManager db) async {
    int allFilesLength = 0;
    int allLoadedFilesLengh = 0;
    var locationsMap =
        await (await db.locationsDao()).findLocationsByHotelId(id) ?? [];
    var locations =
        locationsMap.map((map) => LocationModel.fromMap(map)).toList();
    for (var location in locations) {
      var files =
          await (await db.filesDao()).findFilesByLocationId(location.localId) ??
              [];
      files.forEach((file) {
        if (file.deleted == false) {
          allFilesLength++;
          if (file.synced) {
            allLoadedFilesLengh += 1;
          }
        }
      });
    }
    if (allFilesLength != 0) {
      return 100 * allLoadedFilesLengh / allFilesLength;
    } else {
      return -1;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'synced': synced ? 1 : 0,
      'deleted': deleted ? 1 : 0,
      'name': name,
      'pathOfProfilePhoto': pathOfProfilePhoto,
      'profilePhotoIsChanged': profilePhotoIsChanged ? 1 : 0,
      'country': country,
      'resort': resort
    };
  }

  MyHotelModel.fromMap(Map<String, dynamic> map) {
    id = map['id'];
    description = map['description'];
    createdAt = map['createdAt'];
    updatedAt = map['updatedAt'];
    synced = map['synced'] == 1;
    deleted = map['deleted'] == 1;
    name = map['name'];
    pathOfProfilePhoto = map['pathOfProfilePhoto'];
    profilePhotoIsChanged = map['profilePhotoIsChanged'] == 1;
    country = map['country'];
    resort = map['resort'];
  }
}
