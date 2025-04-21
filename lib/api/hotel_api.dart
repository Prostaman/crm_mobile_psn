import 'package:flutter/foundation.dart';
import 'package:psn.hotels.hub/api/base_api.dart';
import 'package:psn.hotels.hub/models/entities_database/my_hotel_model.dart';
import 'package:psn.hotels.hub/models/response_models/base_model_response.dart';
import 'package:psn.hotels.hub/models/response_models/hotels_response.dart';
import 'package:psn.hotels.hub/models/response_models/locations_response.dart';

class HotelApi extends BaseApi {
  HotelApi() : super();
   
  // Получим ВСЕ отели
  Future<HotelsResponse?> getAll(String? lastModifyDate, bool developerMode) async {
    try {
      String query = "gethotels";
      // добавляем дату последней модификации если надо
      // Если пустая - берем первое января 2020
      query += lastModifyDate != null ? "?lastModifyDate=$lastModifyDate" : "?lastModifyDate=01.01.2000";
      // добавляем developerMode
      query += "&devMode=$developerMode";
      // отправляем запрос
      var response = await super.get(query);
      debugPrint("response:${response.toString()}");
      var model = await compute(parseHotels, response.data);
      debugPrint("After computing hotels: ${model.list?.length}");
      return model;
    } catch (e) {
      //throw e;
      debugPrint("Error getAllHotels:$e");
      return null;
    }
  }

  // Обновит отель
  Future<BaseModelResponse?> updateMyHotel(MyHotelModel myHotel) async {
    try {
      var response = await super.post("AddHotelReview/", {
        "id": myHotel.id,
        "hotelId": myHotel.id,
        "description": myHotel.description});

      // return JsonMapper.deserialize<BaseModelResponse>(response.toString());
      return BaseModelResponse.fromJson(response.data);
    } catch (e) {
      throw e;
    }
  }

  Future<BaseModelResponse?> deleteMyHotel({required int myHotelId}) async {
    try {
      var response = await super.post("DeleteHotel/$myHotelId", {});
      return BaseModelResponse.fromJson(response.data);
    } catch (e) {
      print("Error getting response deleteMyHotel: $e");
      throw e;
    }
  }
}

HotelsResponse parseHotels(dynamic responseBody) {
  return HotelsResponse.fromJson(responseBody);
  //return JsonMapper.deserialize<HotelsResponse>(responseBody);
}

LocationsResponse parseLocations(dynamic responseBody) {
  return LocationsResponse.fromJson(responseBody);
  // return JsonMapper.deserialize<HotelsResponse>(responseBody);
}
