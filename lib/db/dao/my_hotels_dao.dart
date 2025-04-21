import 'package:flutter/material.dart';
import 'package:psn.hotels.hub/db/dao/hotels_dao.dart';
import 'package:psn.hotels.hub/helpers/firebase/firebase_crashlytics_helper.dart';
import 'package:psn.hotels.hub/models/entities_database/hotel_model.dart';
import 'package:psn.hotels.hub/models/entities_database/location_model.dart';
import 'package:psn.hotels.hub/models/entities_database/my_hotel_model.dart';
import 'package:psn.hotels.hub/repository/repository_container.dart';
import 'package:sqflite/sqflite.dart';

import 'files_dao.dart';
import 'locations_dao.dart';

class MyHotelsDao {
  final String tableName;
  final Database _database;

  MyHotelsDao(this._database, this.tableName);

  Future<void> insertMyHotel(MyHotelModel myHotel) async {
    try {
      //Database db = await database;
      await _database.insert(tableName, myHotel.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      FirebaseCrashlyticsHelper.recordDaoLocalDBError(e.toString(), "insertMyHotel");
      throw e;
    }
  }

  Future<void> insertMyHotels(List<MyHotelModel> myHotels) async {
    try {
      //Database db = await database;
      Batch batch = _database.batch();
      for (var myHotel in myHotels) {
        batch.insert(tableName, myHotel.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    } catch (e) {
      FirebaseCrashlyticsHelper.recordDaoLocalDBError(e.toString(), "insertMyHotels");
      throw e;
    }
  }

  Future<Map<String, dynamic>?> findMyHotelById(int id) async {
    try {
      //Database db = await database;
      List<Map<String, dynamic>> hotels = await _database.query(
        tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
      if (hotels.isNotEmpty) {
        return hotels.first;
      } else {
        return null;
      }
    } catch (e) {
      FirebaseCrashlyticsHelper.recordDaoLocalDBError(e.toString(), "findMyHotelById");
      throw e;
    }
  }

  Future<List<MyHotelModel>> findMyHotelsWithChangedProfilePhoto() async {
    try {
      //Database db = await database;
      List<Map<String, dynamic>> myHotelsListMap = (await _database.query(
        tableName,
        where: 'profilePhotoIsChanged = ?',
        whereArgs: [true],
      ));
      // Создаем список для хранения экземпляров MyHotelModel
      List<MyHotelModel> myHotelsList = [];
      // Проходимся по каждому элементу в списке Map и создаем экземпляр MyHotelModel
      for (var hotelMap in myHotelsListMap) {
        MyHotelModel hotel = MyHotelModel.fromMap(hotelMap);
        myHotelsList.add(hotel);
      }
      return myHotelsList;
    } catch (e) {
      FirebaseCrashlyticsHelper.recordDaoLocalDBError(e.toString(), "findMyHotelWithChangedProfilePhoto");
      throw e;
    }
  }

  Future<void> updateMyHotel(int id, MyHotelModel newMyHotel) async {
    try {
      //Database db = await database;
      await _database.update(
        tableName,
        newMyHotel.toMap(),
        where: 'id = ?',
        whereArgs: [id],
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      FirebaseCrashlyticsHelper.recordDaoLocalDBError(e.toString(), "updateMyHotel");
      throw e;
    }
  }

  Future<List<Map<String, dynamic>>> getAllMyHotels() async {
    try {
      //Database db = await database;
      return await _database.query(tableName);
    } catch (e) {
      FirebaseCrashlyticsHelper.recordDaoLocalDBError(e.toString(), "getAllMyHotels");
      throw e;
    }
  }

  Future<void> deleteRussianAndBelorusianEverything() async {
    try {
      var db = RepositoryContainer().myHotelRepository.db;
      HotelsDao hotelsDao = await db.hotelsDao();
      LocationsDao locationsDao = await db.locationsDao();
      FilesDao filesDao = await db.filesDao();
      List<Map<String, dynamic>> hotels = await _database.query(
        'hotels_table',
        where: 'country IN (?, ?)',
        whereArgs: ['Россия', 'Беларусь'],
      );
      for (var hotelMap in hotels) {
        HotelModel hotel = HotelModel.fromMap(hotelMap);
        var myHotelMap = await findMyHotelById(hotel.id);
        if (myHotelMap != null) {
          MyHotelModel? myHotel = MyHotelModel.fromMap(myHotelMap);
          var locationsMap = await (await db.locationsDao()).findLocationsByHotelId(myHotel.id) ?? [];
          var locations = locationsMap.map((map) => LocationModel.fromMap(map)).toList();
          for (var location in locations) {
            var files = await filesDao.findFilesByLocationId(location.localId) ?? [];
            for (var file in files) {
              await filesDao.deleteFile(file.localId, file.localPath);
            }
          }
          await (locationsDao).deleteLocationsByHotelId(myHotel.id);
          debugPrint('Удаление вражеского моего отеля с контентом');
          await deleteMyHotel(myHotel.id);
        }
        await hotelsDao.deleteHotel(hotel.id);
      }
    } catch (e) {
      FirebaseCrashlyticsHelper.recordDaoLocalDBError(e.toString(), "Удаление белорусских и русских отелей");
    }
  }

  Future<void> deleteMyHotel(int id) async {
    try {
      //Database db = await database;
      await _database.delete(
        tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      FirebaseCrashlyticsHelper.recordDaoLocalDBError(e.toString(), "deleteMyHotel");
      throw e;
    }
  }

  Future<void> clearMyHotelsTable() async {
    try {
      //Database db = await database;
      await _database.delete(tableName);
    } catch (e) {
      FirebaseCrashlyticsHelper.recordDaoLocalDBError(e.toString(), "clearMyHotelsTable");
      throw e;
    }
  }
}
