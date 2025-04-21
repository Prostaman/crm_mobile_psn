import 'package:package_info/package_info.dart';
import 'package:psn.hotels.hub/helpers/shared_preferences_utils.dart';

class SettingsService {
  late String version;
  late String buildNumber;
  late bool uploadIfWiFiEnable;
  //late bool deleteContentIfUploaded;
  // переключатель режима developer/нет
  //late bool developerMode;

 
  static SharedPrefUtils sharedPrefUtils = SharedPrefUtils();

 

  int get qualityOfFiles {
    return sharedPrefUtils.getValue("quality", 2) as int;
  } 
  set qualityOfFiles(int value) {
    sharedPrefUtils.setValue("quality", value);
  }

  SettingsService() {
    PackageInfo.fromPlatform().then((PackageInfo packageInfo) {
      version = packageInfo.version;
      buildNumber = packageInfo.buildNumber;
    });

    //developerMode = sharedPrefUtils.getValue("kDevelopEnable", false) as bool;
    uploadIfWiFiEnable = sharedPrefUtils.getValue("kWiFiEnable", false) as bool;
    //deleteContentIfUploaded = sharedPrefUtils.getValue("kDeleteContentEnable", false) as bool;
    //qualityOfFiles=sharedPrefUtils.getValue('quality', 2) as int;
  }

  // saveUploadIsDevelopEnable(bool mode) {
  //   sharedPrefUtils.setValue("kDevelopEnable", mode);
  //   developerMode = mode;
  // }

  saveUploadIfWifiEnable(bool enable) {
    sharedPrefUtils.setValue("kWiFiEnable", enable);
    uploadIfWiFiEnable = enable;
  }

  // saveDeleteContentEnable(bool enable) {
  //   sharedPrefUtils.setValue("kDeleteContentEnable", enable);
  //   deleteContentIfUploaded = enable;
  // }


}
