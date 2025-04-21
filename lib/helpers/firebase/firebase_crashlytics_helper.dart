import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:psn.hotels.hub/models/response_models/base_model_response.dart';

class FirebaseCrashlyticsHelper {
  static Future<void> recordApiError(BaseModelResponse? response, String nameOfMethod) async {
    if (response != null) {
      var errors = response.errors;
      for (int index = 0; index < errors.length; index++) {
        String error = "API: $nameOfMethod error number: $index\nerror code: ${errors[index].code}\nerror message: ${errors[index].message}";
        debugPrint(error);
       // await FirebaseCrashlytics.instance.log(error);
        await FirebaseCrashlytics.instance.recordFlutterError(FlutterErrorDetails(exception: error));
      }
    } else {
      String error = "$nameOfMethod, null reponse";
      debugPrint(error);
      //await FirebaseCrashlytics.instance.log(error);
      await FirebaseCrashlytics.instance.recordFlutterError(FlutterErrorDetails(exception: error));
    }
  }

  static Future<void> recordDaoLocalDBError(String e, String nameOfMethod) async {
    String error = "Local db, $nameOfMethod, error:$e";
    debugPrint(error);
    //await FirebaseCrashlytics.instance.log(error);
    await FirebaseCrashlytics.instance.recordFlutterError(FlutterErrorDetails(exception: error));
  }

}
