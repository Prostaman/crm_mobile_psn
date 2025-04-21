import 'package:flutter/foundation.dart';
import 'package:psn.hotels.hub/api/base_api.dart';
import 'package:psn.hotels.hub/models/response_models/categories_of_locations_response.dart';

class CategoryApi extends BaseApi {
  CategoryApi() : super();
   
  // Получим ВСЕ отели
  Future<CategoriesResponse?> getAll() async {
    try {
      String query = "GetFacilityCategories";
      var response = await super.get(query);
      debugPrint("Get all categories response:${response.toString()}");
      return parseCategories(response.data);
    } catch (e) {
      //throw e;
      debugPrint("Error Get all categories:$e");
      return null;
    }
  }

  CategoriesResponse parseCategories(dynamic responseBody) {
  return CategoriesResponse.fromJson(responseBody);
  //return JsonMapper.deserialize<HotelsResponse>(responseBody);
}
}
