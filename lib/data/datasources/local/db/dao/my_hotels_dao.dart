import 'dart:io';

import 'package:flutter/material.dart';
import 'package:psn.hotels.hub/data/datasources/local/db/dao/hotels_dao.dart';
import 'package:psn.hotels.hub/infrastructure/firebase/firebase_crashlytics_helper.dart';
import 'package:psn.hotels.hub/data/models/entities_database/hotel_model.dart';
import 'package:psn.hotels.hub/data/models/entities_database/location_model.dart';
import 'package:psn.hotels.hub/data/models/entities_database/my_hotel_model.dart';
import 'package:psn.hotels.hub/data/repository/repository_container.dart';
import 'package:sqflite/sqflite.dart';

import 'files_dao.dart';
import 'locations_dao.dart';

class MyHotelsDao {
  final String tableName;
  final Database _database;

  MyHotelsDao(this._database, this.tableName);

  Future<void> insertMyHotel(MyHotelModel myHotel) async {
    try {
      await _database.insert(tableName, myHotel.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      FirebaseCrashlyticsHelper.recordDaoLocalDBError(
          e.toString(), "insertMyHotel");
      throw e;
    }
  }

  Future<void> insertMyHotels(List<MyHotelModel> myHotels) async {
    try {
      Batch batch = _database.batch();
      for (var myHotel in myHotels) {
        batch.insert(tableName, myHotel.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    } catch (e) {
      FirebaseCrashlyticsHelper.recordDaoLocalDBError(
          e.toString(), "insertMyHotels");
      throw e;
    }
  }

  Future<Map<String, dynamic>?> findMyHotelById(int id) async {
    try {
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
      FirebaseCrashlyticsHelper.recordDaoLocalDBError(
          e.toString(), "findMyHotelById");
      throw e;
    }
  }

  Future<List<MyHotelModel>> findMyHotelsWithChangedProfilePhoto() async {
    try {
      //Database db = await database;
      List<Map<String, dynamic>> myHotelsListMap = (await _database.query(
        tableName,
        where: 'profilePhotoIsChanged = ?',
        whereArgs: [1],
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
      FirebaseCrashlyticsHelper.recordDaoLocalDBError(
          e.toString(), "findMyHotelWithChangedProfilePhoto");
      throw e;
    }
  }

  Future<void> updateMyHotel(int id, MyHotelModel newMyHotel) async {
    try {
      await _database.update(
        tableName,
        newMyHotel.toMap(),
        where: 'id = ?',
        whereArgs: [id],
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      FirebaseCrashlyticsHelper.recordDaoLocalDBError(
          e.toString(), "updateMyHotel");
      throw e;
    }
  }

  Future<List<Map<String, dynamic>>> getAllMyHotelsNotDeleted(
      {int? limit, int? offset, String? search}) async {
    debugPrint('getAllMyHotelsForUI');
    try {
      bool hasCyrillic(String text) {
        RegExp regex = RegExp(r'[а-яА-ЯёЁ]');
        return regex.hasMatch(text);
      }

      if (search != null &&
          search.trim().isNotEmpty &&
          Platform.isIOS &&
          hasCyrillic(search)) {
        List<Map<String, dynamic>> allMyHotels = await _database.query(
          tableName,
          where: 'deleted = 0',
          orderBy: 'createdAt DESC',
        );

        List<String> searchWords =
            search.trim().toLowerCase().split(RegExp(r'\s+'));

        var filtered = allMyHotels.where((hotelMap) {
          String name = (hotelMap['name'] ?? "").toString().toLowerCase();
          return searchWords.every((word) => name.contains(word));
        }).toList();

        if (offset != null || limit != null) {
          int start = offset ?? 0;
          int end = (limit != null) ? start + limit : filtered.length;
          if (start > filtered.length) return [];
          if (end > filtered.length) end = filtered.length;
          return filtered.sublist(start, end);
        }
        return filtered;
      } else {
        String? where;
        List<dynamic>? whereArgs;

        if (search != null && search.trim().isNotEmpty) {
          List<String> words = search.trim().split(RegExp(r'\s+'));
          where = words.map((w) => 'LOWER(name) LIKE ?').join(' AND ') +
              ' AND deleted = 0';
          whereArgs = words.map((w) => '%${w.toLowerCase()}%').toList();
        } else {
          where = 'deleted = 0';
        }

        return await _database.query(
          tableName,
          limit: limit,
          offset: offset,
          where: where,
          whereArgs: whereArgs,
          orderBy: 'createdAt DESC',
        );
      }
    } catch (e) {
      FirebaseCrashlyticsHelper.recordDaoLocalDBError(
          e.toString(), "getAllMyHotelsUI");
      throw e;
    }
  }

  Future<List<Map<String, dynamic>>> getAllMyHotelsToSynchronization() async {
    debugPrint('getAllMyHotelsSynchronization');
    try {
      return await _database.query(
        where: 'synced = 0 OR deleted = 1',
        tableName,
      );
    } catch (e) {
      FirebaseCrashlyticsHelper.recordDaoLocalDBError(
          e.toString(), "getAllMyHotelsSynchronization");
      throw e;
    }
  }

  Future<int> getMyHotelsCount({String? search}) async {
    try {
      bool hasCyrillic(String text) {
        RegExp regex = RegExp(r'[а-яА-ЯёЁ]');
        return regex.hasMatch(text);
      }

      if (search != null &&
          search.trim().isNotEmpty &&
          Platform.isIOS &&
          hasCyrillic(search)) {
        List<Map<String, dynamic>> allMyHotels = await _database.query(
          tableName,
          where: 'deleted = 0',
          columns: ['name'],
        );

        List<String> searchWords =
            search.trim().toLowerCase().split(RegExp(r'\s+'));

        return allMyHotels.where((hotelMap) {
          String name = (hotelMap['name'] ?? "").toString().toLowerCase();
          return searchWords.every((word) => name.contains(word));
        }).length;
      } else {
        String sql = 'SELECT COUNT(*) FROM $tableName WHERE deleted = 0';
        List<dynamic> args = [];
        if (search != null && search.trim().isNotEmpty) {
          List<String> words = search.trim().split(RegExp(r'\s+'));
          sql += ' AND ' + words.map((w) => 'LOWER(name) LIKE ?').join(' AND ');
          args.addAll(words.map((w) => '%${w.toLowerCase()}%'));
        }
        var result = await _database.rawQuery(sql, args);
        return Sqflite.firstIntValue(result) ?? 0;
      }
    } catch (e) {
      FirebaseCrashlyticsHelper.recordDaoLocalDBError(
          e.toString(), "getMyHotelsCount");
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
          var locationsMap = await (await db.locationsDao())
                  .findLocationsByHotelId(myHotel.id) ??
              [];
          var locations =
              locationsMap.map((map) => LocationModel.fromMap(map)).toList();
          for (var location in locations) {
            var files =
                await filesDao.findFilesByLocationId(location.localId) ?? [];
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
      FirebaseCrashlyticsHelper.recordDaoLocalDBError(
          e.toString(), "Удаление белорусских и русских отелей");
    }
  }

  Future<void> deleteMyHotel(int id) async {
    try {
      await _database.delete(
        tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      FirebaseCrashlyticsHelper.recordDaoLocalDBError(
          e.toString(), "deleteMyHotel");
      throw e;
    }
  }

  Future<void> clearMyHotelsTable() async {
    try {
      await _database.delete(tableName);
    } catch (e) {
      FirebaseCrashlyticsHelper.recordDaoLocalDBError(
          e.toString(), "clearMyHotelsTable");
      throw e;
    }
  }
}
