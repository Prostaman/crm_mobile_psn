import 'package:psn.hotels.hub/blocks/base_cubit/base_cubit.dart';
import 'package:psn.hotels.hub/blocks/settings/settings_state.dart';
import 'package:psn.hotels.hub/db/db_manager.dart';
import 'package:psn.hotels.hub/helpers/file_utility.dart';
import 'package:psn.hotels.hub/models/entities_database/file_model.dart';
import 'package:psn.hotels.hub/models/response_models/file_model_response.dart';
import 'package:psn.hotels.hub/services/service_container.dart';

import '../../services/synchronization_service.dart';

class SettingsCubit extends BaseCubit {
  SettingsCubit()
      : super(SettingsState(
          wifiEnabled: ServiceContainer().settingsService.uploadIfWiFiEnable,
          qualityIndex: ServiceContainer().settingsService.qualityOfFiles,
        ));

  bool wasDeleting = false;

  void toggleWifi(bool value) {
    ServiceContainer().settingsService.saveUploadIfWifiEnable(value);
    if (state is SettingsState) {
      emit((state as SettingsState).copyWith(wifiEnabled: value));
    }
  }

  void setQuality(int index) {
    ServiceContainer().settingsService.qualityOfFiles = index;
    if (state is SettingsState) {
      emit((state as SettingsState).copyWith(qualityIndex: index));
    }
  }

  Future<void> clearSyncedMedia() async {
    try {
      DBManager db = DBManager();
      List<FileModel> allFiles = await (await db.filesDao()).getAllFiles();

      for (var file in allFiles) {
        if (file.synced) {
          await FileUtility.deleteFile(file.localPath);
          if (file.type == FileModelType.Video &&
              (file.thumb ?? '').isNotEmpty) {
            await FileUtility.deleteFile(file.thumb!);
          }
          await (await db.filesDao()).deleteFile(file.localId, file.localPath);
        }
      }

      SinkService().syncFilesObserver.add(-1);
      SinkService().syncLocationsObserver.add(-1);
      SinkService().syncMyHotelsObserver.add(-1);
    } catch (e) {
      catchError(e);
    }
  }
}
