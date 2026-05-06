import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:psn.hotels.hub/data/datasources/remote/api/api_container.dart';
import 'package:psn.hotels.hub/infrastructure/firebase/firebase_initialization.dart';
import 'package:psn.hotels.hub/infrastructure/shared_preferences_utils.dart';
import 'package:psn.hotels.hub/main.reflectable.dart';
import 'package:psn.hotels.hub/data/models/response_models/user_model.dart';
import 'package:psn.hotels.hub/domain/services/auth_service.dart';
import 'package:psn.hotels.hub/domain/services/synchronization_service.dart';
import 'package:workmanager/workmanager.dart';

void initWorkManagerSyncing() {
  print('Was init workmanager');
  Workmanager().initialize(callbackDispatcher);

  Workmanager().registerPeriodicTask("TASK_SYNC_PSN", "SYNC_PSN",
      frequency: Duration(hours: 3),
      constraints: Constraints(
          // connected or metered mark the task as requiring internet
          networkType: NetworkType.connected));
}

@pragma(
    'vm:entry-point') // Mandatory if the App is obfuscated or using Flutter 3.1+
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      debugPrint('Workmanager is started: $task');
      initializeReflectable();
      await SharedPrefUtils().init();
      UserModel? userModel = await AuthService().loadUserFromShared();
      if (userModel != null &&
          userModel.token != null &&
          userModel.token!.isNotEmpty) {
        ApiContainer().setToken(userModel.token!);
        await initFirebase();
        await FirebaseCrashlytics.instance
            .setUserIdentifier(userModel.userName!);
        await SinkService().startSynchronization();
      }
    } catch (e) {
      String error = "Workmanager error: $e";
      await FirebaseCrashlytics.instance
          .recordFlutterError(FlutterErrorDetails(exception: error));
    }

    return true;
  });
}
