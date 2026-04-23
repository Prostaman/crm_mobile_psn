import 'package:flutter/foundation.dart';
import 'package:psn.hotels.hub/api/api_container.dart';
import 'package:psn.hotels.hub/api/hotel_api.dart';
import 'package:psn.hotels.hub/db/db_manager.dart';
import 'package:psn.hotels.hub/models/entities_database/hotel_model.dart';
import 'package:psn.hotels.hub/models/entities_database/my_hotel_model.dart';
import 'package:psn.hotels.hub/services/service_container.dart';

class MyHotelRepository {
  final HotelApi hotelApi = ApiContainer().hotelApi;
  // Assuming you have a DB instance
  DBManager db = DBManager();

  MyHotelRepository();

  Future<List<MyHotelModel>> getMyHotelsNotDeleted(
      {int? limit, int? offset, String? search}) async {
    try {
      List<Map<String, dynamic>> myHotelsMaps = await (await db.myHotelsDao())
          .getAllMyHotelsNotDeleted(
              limit: limit, offset: offset, search: search);
      List<MyHotelModel> myHotels = myHotelsMaps
          .map((map) => MyHotelModel.fromMap(map))
          .where((element) => element.deleted == false)
          .toList();
      return myHotels;
    } catch (e) {
      throw e;
    }
  }

  Future<int> getMyHotelsCount({String? search}) async {
    return await (await db.myHotelsDao()).getMyHotelsCount(search: search);
  }

  Future<MyHotelModel> addMyHotel({required HotelModel hotel}) async {
    try {
      var foundHotel = await (await db.myHotelsDao()).findMyHotelById(hotel.id);
      if (foundHotel == null) {
        MyHotelModel myHotel = MyHotelModel();
        myHotel.id = hotel.id;
        myHotel.name = hotel.name;
        myHotel.createdAt = DateTime.now().toIso8601String();
        myHotel.updatedAt = DateTime.now().toIso8601String();
        (await db.myHotelsDao()).insertMyHotel(myHotel);
        return myHotel;
      } else {
        var model = MyHotelModel.fromMap(foundHotel);
        model.deleted = false;
        await (await db.myHotelsDao()).updateMyHotel(model.id, model);
        return model;
      }
    } catch (e) {
      throw e;
    }
  }

  Future<MyHotelModel> updateMyHotel({required MyHotelModel model}) async {
    try {
      model.synced = false;
      await (await db.myHotelsDao()).updateMyHotel(model.id, model);
      // print("startSinc updateMyHotel");
      // ServiceContainer().sinkService.startSinc();
      return model;
    } catch (e) {
      throw e;
    }
  }

  Future<void> removeHotel({required MyHotelModel myHotel}) async {
    myHotel.synced = false;
    myHotel.deleted = true;
    await (await db.myHotelsDao()).updateMyHotel(myHotel.id, myHotel);
    debugPrint("start Synchronization removeHotel");
    ServiceContainer().sinkService.startSynchronization();
  }

  Future<void> removeAll() async {
    try {
      await (await db.myHotelsDao()).clearMyHotelsTable();
    } catch (e) {
      throw e;
    }
  }

  Future<List<MyHotelModel>> get allMyHotelsNotDeleted async {
    List<Map<String, dynamic>> myHotelsMaps =
        await (await db.myHotelsDao()).getAllMyHotelsNotDeleted();
    List<MyHotelModel> myHotels =
        myHotelsMaps.map((map) => MyHotelModel.fromMap(map)).toList();
    return myHotels;
  }

  Future<List<MyHotelModel>> get allMyHotelsToSynchronization async {
    List<Map<String, dynamic>> myHotelsMaps =
        await (await db.myHotelsDao()).getAllMyHotelsToSynchronization();
    List<MyHotelModel> myHotels =
        myHotelsMaps.map((map) => MyHotelModel.fromMap(map)).toList();
    return myHotels;
  }
}
