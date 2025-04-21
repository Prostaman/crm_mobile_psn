import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:psn.hotels.hub/api/hotel_api.dart';
import 'package:psn.hotels.hub/db/dao/my_hotels_dao.dart';
import 'package:psn.hotels.hub/db/db_manager.dart';
import 'package:psn.hotels.hub/helpers/format_date.dart';
import 'package:psn.hotels.hub/models/entities_database/hotel_model.dart';
import 'package:psn.hotels.hub/models/entities_database/location_model.dart';
import 'package:psn.hotels.hub/models/entities_database/my_hotel_model.dart';
import 'package:psn.hotels.hub/models/response_models/hotels_response.dart';
import '../api/api_container.dart';
import '../db/dao/files_dao.dart';
import '../db/dao/hotels_dao.dart';
import '../db/dao/locations_dao.dart';
import '../helpers/firebase/firebase_crashlytics_helper.dart';
import '../helpers/shared_preferences_utils.dart';
import 'repository_container.dart';

// Репозиторий для список отелей, который показываем  при добавлении нового отеля
// к своим существующим
class HotelListRepository {
  // ключ покажет дату последнего обновления
  final String _kLastUpdated = "kLastUpdated";
  // объект для работы с API
  final HotelApi hotelApi = ApiContainer().hotelApi;
  // shared preferences
  SharedPrefUtils sharedPrefUtils = SharedPrefUtils();

  // Assuming you have a DB instance
  DBManager db = DBManager();

  HotelListRepository();

  // вернет дату последнего обновления
  Future<String?> _loadLastUpdatedDate() async {
    await sharedPrefUtils.init(); // Ensure preferences are initialized
    String value = sharedPrefUtils.getValue(_kLastUpdated, "").toString();
    return value == "" ? null : value;
  }

  // запишет дату последнего обновления
  Future<String> _saveLastUpdatedDate() async {
    await sharedPrefUtils.init();
    String date = formatDate(DateTime.now(), format: DateFormatType.Date);
    sharedPrefUtils.setValue(_kLastUpdated, date);
    return date;
  }

  //***************************************************
  // PUBLIC Methods
  //***************************************************

  // Вернет список отсортированых отелей по дистанции к пользователю  из локальной базы данных
  Future<List<HotelModel>> getHotelsBySearchTextAndSortedByDistanceRepository(int qtyToShow, String searchText) async {
    late Position position;
    try {
      // получим текущую позицию пользователя(телефона)
      position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.bestForNavigation);
    } catch (e) {
      position = Position(
        latitude: 0.0,
        longitude: 0.0,
        timestamp: DateTime.now(),
        accuracy: 0.0,
        altitude: 0.0,
        heading: 0.0,
        speed: 0.0,
        altitudeAccuracy: 0.0,
        headingAccuracy: 0.0,
        speedAccuracy: 0.0,
      );
      debugPrint("Error getHotelsBySearchTextAndSortedByDistanceRepository:$e");
      await FirebaseCrashlytics.instance.log("Didn't get position of user, null Position");
      await FirebaseCrashlytics.instance.recordFlutterError(FlutterErrorDetails(exception: e));
    }
    List<HotelModel> hotels = await (await db.hotelsDao()).getHotelsSortedByDistance(position.latitude, position.longitude, qtyToShow, searchText);
    debugPrint("getHotelsWithOffsetAndSortedByDistance:\n" + hotels.length.toString());
    hotels.forEach((element) {
      debugPrint(" ${element.name}");
    });
    return hotels;
  }

  // Вернет отель по id из локальной базы данных
  Future<HotelModel?> findHotelFromLocalDBById(int id) async {
    try {
      Map<String, dynamic>? hotelMap = await (await db.hotelsDao()).findHotelById(id);
      if (hotelMap != null)
        return HotelModel.fromMap(hotelMap);
      else
        return null;
    } catch (e) {
      throw e;
    }
  }

  StreamController observerOfLoadingHotels = new StreamController<bool>.broadcast();
  int attempt = 0;
  // Загрузит отели из ПСН БД
  Future<bool> downloadAllHotels() async {
    // получим дату последнего обновления
    String? lastUpdated = await _loadLastUpdatedDate();
    // закачаем отели
    var response = await hotelApi.getAll(lastUpdated, false);
    if (response != null && response.success == true && response.list != null) {
      var items = await compute(computeGenerateItems, response);
      debugPrint("Items that will put to db: ${items.length}");
      if (items.isNotEmpty) {
        await (await db.hotelsDao()).insertOrUpdateHotels(items);
      }

      //и установим дату обновления
      await _saveLastUpdatedDate();
      attempt = 0;
      return true;
    } else {
      FirebaseCrashlyticsHelper.recordApiError(response, "Attempt: $attempt. getAllHotels");
      attempt++;
      if (attempt < 4) {
        await Future.delayed(Duration(seconds: 3));
        await downloadAllHotels();
      } else {
        attempt = 0;
        observerOfLoadingHotels.add(true);
        return false;
      }
    }
    return false;
  }

  Future<void> deleteRussianAndBelorusianHotels() async {
    try {
      var db = RepositoryContainer().myHotelRepository.db;
      HotelsDao hotelsDao = await db.hotelsDao();
      MyHotelsDao myHotelsDao = await db.myHotelsDao();
      LocationsDao locationsDao = await db.locationsDao();
      FilesDao filesDao = await db.filesDao();
      List<HotelModel> hotels = await hotelsDao.getAllRussianAndBelorusianHotels();
      for (var hotel in hotels) {
        var myHotelMap = await myHotelsDao.findMyHotelById(hotel.id);
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
          await myHotelsDao.deleteMyHotel(myHotel.id);
        }
        await hotelsDao.deleteHotel(hotel.id);
      }
    } catch (e) {
      FirebaseCrashlyticsHelper.recordDaoLocalDBError(e.toString(), "Удаление белорусских и русских отелей");
    }
  }
}

// соберем результаты в массив ВАЖНО! ДОЛЖЕН БЫТЬ ВНЕ КЛАССА МЕТОД
Map<dynamic, HotelModel> computeGenerateItems(HotelsResponse response) {
  Map<dynamic, HotelModel> updatedItems = {};
  response.list?.forEach((element) {
    updatedItems[element.id] = element;
  });
  return updatedItems;
}

// Класс для фильтрации отелей
class FilterHotelsModel {
  double lat;
  double lon;
  Iterable<HotelModel> models;

  FilterHotelsModel({required this.lat, required this.lon, required this.models});
}
