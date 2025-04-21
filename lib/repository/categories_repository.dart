import 'dart:async';

import 'package:flutter/material.dart';
import 'package:psn.hotels.hub/api/api_container.dart';
import 'package:psn.hotels.hub/api/category_of_location_api.dart';
import 'package:psn.hotels.hub/db/db_manager.dart';
import 'package:psn.hotels.hub/helpers/firebase/firebase_crashlytics_helper.dart';
import 'package:psn.hotels.hub/models/response_models/categories_of_locations_response.dart';

class CategoriesRepository {
    // объект для работы с API
  final CategoryApi categoryApi = ApiContainer().categoryApi;

  StreamController observerOfLoadingCategories = new StreamController<bool>.broadcast();
  int attempt = 0;
  
  DBManager db = DBManager();
  
  Future<bool> downloadCategories() async {
    // закачаем отели
    CategoriesResponse? response = await categoryApi.getAll();
    if (response != null && response.success == true && response.list != null) {
      debugPrint("Catergories that will put to db: ${response.list!.length}");
      if (response.list!.isNotEmpty) {
          await (await db.categoriesDao()).insertCategories(response.list!);
      }

      attempt = 0;
      return true;
    } else {
      FirebaseCrashlyticsHelper.recordApiError(response, "Attempt: $attempt. getAllCategories");
      attempt++;
      if (attempt < 4) {
        await Future.delayed(Duration(seconds: 3));
        await downloadCategories();
      } else {
        attempt = 0;
        observerOfLoadingCategories.add(true);
        return false;
      }
    }
    return false;
  }

}
