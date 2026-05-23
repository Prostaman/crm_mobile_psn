import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:psn.hotels.hub/infrastructure/firebase/firebase_crashlytics_helper.dart';
import 'package:psn.hotels.hub/data/models/entities_database/hotel_model.dart';
import 'package:sqflite/sqflite.dart';

class HotelsDao {
  final String tableName;
  final Database _database;

  // Database db = await _database;
  HotelsDao(this._database, this.tableName);

  StreamController observerOfInsertingHotels =
      new StreamController<int>.broadcast();

  // Hotels
  Future<void> insertOrUpdateHotels(Map<dynamic, HotelModel> hotels) async {
    try {
      observerOfInsertingHotels.add(0);
      debugPrint("start inserting database");
      const int limitOfInsertingOrUpdating = 30000;
      int onePercentOfLoading = (hotels.entries.length / 100).ceil();
      int quantityOfIteration =
          (hotels.entries.length / limitOfInsertingOrUpdating).ceil();
      for (var i = 0; i < quantityOfIteration; i++) {
        Batch batch = _database.batch();
        for (var entry in hotels.entries
            .skip(limitOfInsertingOrUpdating * i)
            .take(limitOfInsertingOrUpdating)) {
          var hotel = entry.value;
          batch.insert(
            tableName,
            hotel.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit(noResult: true);
        debugPrint(
            "inserted to db: ${(i * limitOfInsertingOrUpdating / onePercentOfLoading).round()} %");
        observerOfInsertingHotels.add(
            (i * limitOfInsertingOrUpdating / onePercentOfLoading).round());
      }
      debugPrint("inserted to db: 100 %");
      observerOfInsertingHotels.add((100));
    } catch (e) {
      FirebaseCrashlyticsHelper.recordDaoLocalDBError(
          e.toString(), "insertOrUpdateHotels");
      throw e;
    }
  }

  Future<List<HotelModel>> getAllRussianAndBelorusianHotels() async {
    // Создаем список для хранения экземпляров MyHotelModel
    List<HotelModel> hotelsList = [];
    try {
      List<Map<String, dynamic>> hotelsListMap = await _database.query(
        tableName,
        where: 'country IN (?, ?)',
        whereArgs: ['Россия', 'Беларусь'],
      );

      // Проходимся по каждому элементу в списке Map и создаем экземпляр MyHotelModel
      for (var hotelMap in hotelsListMap) {
        HotelModel location = HotelModel.fromMap(hotelMap);
        hotelsList.add(location);
      }
    } catch (e) {
      FirebaseCrashlyticsHelper.recordDaoLocalDBError(
          e.toString(), "Удаление белорусских и русских отелей");
    }
    return hotelsList;
  }

  Future<void> deleteHotel(int id) async {
    try {
      await _database.delete(
        tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      FirebaseCrashlyticsHelper.recordDaoLocalDBError(
          e.toString(), "deleteFile");
      throw e;
    }
  }

  Future<bool> isTableHotelsEmpty() async {
    int count = Sqflite.firstIntValue(
            await _database.rawQuery('SELECT COUNT(*) FROM $tableName')) ??
        0;
    return count == 0;
  }

  Future<Map<String, dynamic>?> findHotelById(int id) async {
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
          e.toString(), "findHotelById");
      throw e;
    }
  }

  Future<List<HotelModel>> getHotelsSortedByDistance(double userLat,
      double userLong, int limit, int offset, String searchText) async {
    try {
      bool hasCyrillic(String text) {
        RegExp regex = RegExp(r'[а-яА-Я]');
        return regex.hasMatch(text);
      }

      if (Platform.isIOS && hasCyrillic(searchText)) {
        // Оптимизация: запрашиваем только необходимые поля для фильтрации и сортировки
        List<Map<String, dynamic>> mapListAllHotels = await _database.query(
          tableName,
          columns: ['id', 'name', 'lat', 'long', 'country', 'resort'],
        );

        List<String> searchWords =
            searchText.trim().toLowerCase().split(RegExp(r'\s+'));

        // Сначала фильтруем Map-ы, чтобы не создавать лишние объекты HotelModel
        var filteredMaps = mapListAllHotels.where((hotelMap) {
          String name = (hotelMap['name'] ?? "").toString().toLowerCase();
          return searchWords.every((word) => name.contains(word));
        });

        List<HotelModel> filteredHotels =
            filteredMaps.map((map) => HotelModel.fromMap(map)).toList();

        filteredHotels.sort((a, b) {
          double distanceA = (a.lat - userLat) * (a.lat - userLat) +
              (a.long - userLong) * (a.long - userLong);
          double distanceB = (b.lat - userLat) * (b.lat - userLat) +
              (b.long - userLong) * (b.long - userLong);
          return distanceA.compareTo(distanceB); //sorting by distance to User
        });
        return filteredHotels.skip(offset).take(limit).toList();
      } else {
        List<Map<String, dynamic>> hotels = [];
        String whereClause = '';
        List<dynamic> args = [];
        if (searchText.trim().isNotEmpty) {
          List<String> words = searchText.trim().split(RegExp(r'\s+'));
          whereClause =
              'WHERE ' + words.map((w) => 'LOWER(name) LIKE ?').join(' AND ');
          args = words.map((w) => '%${w.toLowerCase()}%').toList();
        }

        hotels.addAll(await _database.rawQuery('''
        SELECT *, 
        ((lat - $userLat) * (lat - $userLat) + (long - $userLong) * (long - $userLong)) as distance
    FROM $tableName
    $whereClause
    ORDER BY distance
    LIMIT $limit OFFSET $offset
  ''', args));
        List<HotelModel> hotelList = [];
        for (var hotel in hotels) {
          hotelList.add(HotelModel.fromMap(hotel));
        }
        return hotelList;
      }
    } catch (e) {
      FirebaseCrashlyticsHelper.recordDaoLocalDBError(
          e.toString(), "getHotelsSortedByDistance");
      throw e;
    }
  }

  Future<int> getHotelsCount({String? search}) async {
    try {
      String sql = 'SELECT COUNT(*) FROM $tableName';
      List<dynamic> args = [];
      if (search != null && search.trim().isNotEmpty) {
        List<String> words = search.trim().split(RegExp(r'\s+'));
        sql += ' WHERE ' + words.map((w) => 'LOWER(name) LIKE ?').join(' AND ');
        args.addAll(words.map((w) => '%${w.toLowerCase()}%'));
      }
      var result = await _database.rawQuery(sql, args);
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      FirebaseCrashlyticsHelper.recordDaoLocalDBError(
          e.toString(), "getHotelsCount");
      throw e;
    }
  }

  Future<List<String>> getCountryAndResort(int hotelId) async {
    List<String> countryAndResort = [];
    var hotelMap = await findHotelById(hotelId);
    var hotel = HotelModel.fromMap(hotelMap!);
    countryAndResort.add(hotel.country);
    countryAndResort.add(hotel.resort);
    return countryAndResort;
  }
}
