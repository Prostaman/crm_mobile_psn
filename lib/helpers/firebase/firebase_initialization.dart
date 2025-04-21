import 'dart:io';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:psn.hotels.hub/helpers/firebase/firebase_helper_crashlytics_analytics.dart';

Future<void> initFirebase() async {
  await Firebase.initializeApp();
  if (!kDebugMode) {
    if (Platform.isIOS) {
      /// Getting permission for appTrackingTransparency required a delay between prompts.
      if (await AppTrackingTransparency.trackingAuthorizationStatus != TrackingStatus.authorized) {
        final status = await AppTrackingTransparency.requestTrackingAuthorization();
        if (status == TrackingStatus.authorized) {
          await FirebaseHelper.enableCrashlyticsAndAnalytics();
        } else {
          await FirebaseHelper.disableCrashlyticsAndAnalytics();
        }
      } else {
        await FirebaseHelper.enableCrashlyticsAndAnalytics();
      }
    } else {
      await FirebaseHelper.enableCrashlyticsAndAnalytics();
    }
  } else {
    await FirebaseHelper.disableCrashlyticsAndAnalytics();
  }
}