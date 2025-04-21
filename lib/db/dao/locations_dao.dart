import 'package:psn.hotels.hub/helpers/firebase/firebase_crashlytics_helper.dart';
import 'package:psn.hotels.hub/models/entities_database/location_model.dart';
import 'package:sqflite/sqflite.dart';

class LocationsDao {
  final String tableName;
  final Database _database;

  LocationsDao(this._database, this.tableName);

 Future<int> insertLocation(LocationModel location) async {
    //Database db = await database;
    try {
      int id = await _database.insert(tableName, location.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      return id;
    } catch (e) {
      FirebaseCrashlyticsHelper.recordDaoLocalDBError(e.toString(), "insertLocation");
      throw e;
    }
  }

  Future<List<Map<String, dynamic>>?> findLocationsByHotelId(int hotelId) async {
    //Database db = await database;
    try {
      return await _database.query(
        tableName,
        where: 'hotelId = ?',
        whereArgs: [hotelId],
      );
    } catch (e) {
      FirebaseCrashlyticsHelper.recordDaoLocalDBError(e.toString(), "findLocationsByHotelId");
      throw e;
    }
  }

  Future<List<LocationModel>> findLocationsByCloudId(int cloudId) async {
    //Database db = await database;
    try {
      var locations = await _database.query(
        tableName,
        where: 'cloudId = ?',
        whereArgs: [cloudId],
      );
      return locations.map((map) => LocationModel.fromMap(map)).toList();
    } catch (e) {
      FirebaseCrashlyticsHelper.recordDaoLocalDBError(e.toString(), "findLocationsByCloudId");
      throw e;
    }
  }

  Future<LocationModel?> findLocationByLocalId(int localId) async {
    //Database db = await database;
    try {
      var locations = await _database.query(
        tableName,
        where: 'localId = ?',
        whereArgs: [localId],
        limit: 1, // Limiting the result to one row
      );
      if (locations.isNotEmpty) {
        return LocationModel.fromMap(locations.first);
      } else {
        return null; // No matching location found
      }
    } catch (e) {
      FirebaseCrashlyticsHelper.recordDaoLocalDBError(e.toString(), "findLocationByLocalId");
      throw e;
    }
  }

    Future<List<LocationModel>> findLocationsWithChangedProfilePhoto() async {
    try {
      //Database db = await database;
      List<Map<String, dynamic>> locationsListMap = (await _database.query(
        tableName,
        where: 'profilePhotoIsChanged = ?',
        whereArgs: [true],
      ));
      // Создаем список для хранения экземпляров MyHotelModel
      List<LocationModel> locationsList = [];
      // Проходимся по каждому элементу в списке Map и создаем экземпляр MyHotelModel
      for (var locationMap in locationsListMap) {
        LocationModel location = LocationModel.fromMap(locationMap);
        locationsList.add(location);
      }
      return locationsList;
    } catch (e) {
      FirebaseCrashlyticsHelper.recordDaoLocalDBError(e.toString(), "findMyHotelWithChangedProfilePhoto");
      throw e;
    }
  }

  Future<void> updateLocation(int localId, LocationModel newLocation) async {
    //Database db = await database;
    try {
      await _database.update(
        tableName,
        newLocation.toMap(),
        where: 'localId = ?',
        whereArgs: [localId],
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      FirebaseCrashlyticsHelper.recordDaoLocalDBError(e.toString(), "updateLocation");
      throw e;
    }
  }

  

  Future<List<Map<String, dynamic>>> getAllLocations() async {
    //Database db = await database;
    try {
      return await _database.query(tableName);
    } catch (e) {
      FirebaseCrashlyticsHelper.recordDaoLocalDBError(e.toString(), "getAllLocations");
      throw e;
    }
  }

  Future<void> deleteLocationsByHotelId(int hotelId) async {
    //Database db = await database;
    try {
      await _database.delete(
        tableName,
        where: 'hotelId = ?',
        whereArgs: [hotelId],
      );
    } catch (e) {
      FirebaseCrashlyticsHelper.recordDaoLocalDBError(e.toString(), "deleteLocationsByHotelId");
      throw e;
    }
  }

  Future<void> deleteLocation(int localId) async {
    //Database db = await database;
    try {
      await _database.delete(
        tableName,
        where: 'localId = ?',
        whereArgs: [localId],
      );
    } catch (e) {
      FirebaseCrashlyticsHelper.recordDaoLocalDBError(e.toString(), "deleteLocation");
      throw e;
    }
  }

  Future<void> clearLocationsTable() async {
    //Database db = await database;
    try {
      await _database.delete(tableName);
    } catch (e) {
      FirebaseCrashlyticsHelper.recordDaoLocalDBError(e.toString(), "clearLocationsTable");
      throw e;
    }
  }

}
