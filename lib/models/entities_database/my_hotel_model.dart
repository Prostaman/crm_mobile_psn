import 'package:psn.hotels.hub/db/db_manager.dart';
import 'package:psn.hotels.hub/models/entities_database/file_model.dart';
import 'package:psn.hotels.hub/models/entities_database/location_model.dart';
import 'package:psn.hotels.hub/models/response_models/base_model.dart';
import 'package:collection/collection.dart';

import 'hotel_model.dart';

class MyHotelModel extends BaseModel {
  late int id;
  String? description;
  late String createdAt;
  late String updatedAt;
  bool synced = true;
  bool deleted = false;
  late String name;
  String pathOfProfilePhoto = "";
  bool profilePhotoIsChanged = false;

  MyHotelModel();

  dynamic get baseId {
    return id;
  }

  Future<List<String>> getCountryAndResort(DBManager db) async {
    List<String> countryAndResort = [];
    var hotelMap = await (await db.hotelsDao()).findHotelById(id);
    var hotel = HotelModel.fromMap(hotelMap!);
    countryAndResort.add(hotel.country);
    countryAndResort.add(hotel.resort);
    return countryAndResort;
  }

  Future<List<LocationModel>?> getLocations(DBManager db) async {
    List<Map<String, dynamic>>? locationMaps = await (await db.locationsDao()).findLocationsByHotelId(id);
    if (locationMaps != null && locationMaps.isNotEmpty) {
      // Convert each map to a LocationModel object
      List<LocationModel> locations = locationMaps.map((map) => LocationModel.fromMap(map)).toList();
      return locations;
    } else {
      return null; // Return null if no locations are found
    }
  }

  Future<int> getLengthOfAllLocationsInTable(DBManager db) async {
    return (await (await db.locationsDao()).getAllLocations()).length;
  }

  Future<List<FileModel>> getAllFiles(DBManager db) async {
    List<FileModel> files = [];
    final locationsData = await (await db.locationsDao()).findLocationsByHotelId(id);
    if (locationsData != null && locationsData.isNotEmpty) {
      for (var element in locationsData) {
        final locationModel = LocationModel.fromMap(element);
        final viewFiles = await (await db.filesDao()).findFilesByLocationId(locationModel.localId) ?? [];
        for (var viewFile in viewFiles) {
          if (viewFile.deleted == false) {
            files.add(viewFile);
          }
        }
      }
    }
   
    return files;
  }

  Future<bool> getLocationSynced(DBManager db) async {
    var x = await (await db.locationsDao()).findLocationsByHotelId(id);
    return x?.firstWhereOrNull((element) => LocationModel.fromMap(element).synced == false) == null;
  }

  Future<double> getPercentLoadedOfAllFilesOfMyHotel(DBManager db) async {
    int allFilesLength = 0;
    int allLoadedFilesLengh = 0;
    var locationsMap = await (await db.locationsDao()).findLocationsByHotelId(id) ?? [];
    var locations = locationsMap.map((map) => LocationModel.fromMap(map)).toList();
    for (var location in locations) {
      var files = await (await db.filesDao()).findFilesByLocationId(location.localId) ?? [];
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
      'profilePhotoIsChanged': profilePhotoIsChanged ? 1 : 0
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
  }
}
