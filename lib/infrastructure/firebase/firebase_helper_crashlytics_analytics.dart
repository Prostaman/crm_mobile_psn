import 'dart:ui';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';

class FirebaseHelper {
  static Future<void> enableCrashlyticsAndAnalytics() async {
    debugPrint('enableCrashlyticsAndAnalytics');
    //Инициализация Firebase
    FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
    FlutterError.onError = (errorDetails) {
      FirebaseCrashlytics.instance.recordFlutterError(errorDetails);
    };
    // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  static Future<void> disableCrashlyticsAndAnalytics() async {
     debugPrint('disableCrashlyticsAndAnalytics');
    await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(false);
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false);
  }
}
