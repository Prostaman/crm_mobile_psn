import 'dart:io';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:psn.hotels.hub/api/api_container.dart';
import 'package:psn.hotels.hub/helpers/firebase/firebase_initialization.dart';
import 'package:psn.hotels.hub/helpers/shared_preferences_utils.dart';
import 'package:psn.hotels.hub/main.reflectable.dart';
import 'package:psn.hotels.hub/models/response_models/user_model.dart';
import 'package:psn.hotels.hub/services/auth_service.dart';
import 'package:psn.hotels.hub/services/sink_service.dart';
import 'package:workmanager/workmanager.dart';

void initWorkManagerSyncing() {
  print('Was init workmanager');
  Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
  Workmanager().registerPeriodicTask("TASK_SYNC_PSN", "TASK_SYNC_PSN",
      initialDelay: Duration(hours: 3),
      frequency: Duration(hours: 3),
      constraints: Constraints(
          // connected or metered mark the task as requiring internet
          networkType: NetworkType.connected));
}

@pragma('vm:entry-point') // Mandatory if the App is obfuscated or using Flutter 3.1+
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    print('Was executeTask workmanager');
    try {
      initializeReflectable();
      await SharedPrefUtils().init();
      UserModel? userModel = await AuthService().loadUserFromShared();
      ApiContainer().setToken(userModel!.token!);
      await initFirebase();
      await FirebaseCrashlytics.instance.setUserIdentifier(userModel.userName!);
      if (Platform.isIOS) {
        await FirebaseAnalytics.instance.logEvent(name: "start_sinc_from_workmanager_ios",
         parameters: {
        "full_text": "start_sinc_from_workmanager_ios",
    });
      }
      print('start sinc from Workmanager');
      await SinkService().startSinc();
    } catch (e) {
      print('Workmanager error:$e');
      String error = "Workmanager error: $e";
      await FirebaseCrashlytics.instance.recordFlutterError(FlutterErrorDetails(exception: error));
    }

    return true;
  });
}
