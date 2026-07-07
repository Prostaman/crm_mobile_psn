import 'package:psn.hotels.hub/data/datasources/remote/api/api_container.dart';
import 'package:psn.hotels.hub/data/datasources/remote/api/category_of_location_api.dart';
import 'package:psn.hotels.hub/data/datasources/remote/api/files_api.dart';
import 'package:psn.hotels.hub/data/datasources/remote/api/location_api.dart';
import 'package:psn.hotels.hub/data/datasources/local/db/db_manager.dart';
import 'package:psn.hotels.hub/data/models/entities_database/file_model.dart';
import 'package:psn.hotels.hub/data/models/entities_database/my_hotel_model.dart';
import 'package:psn.hotels.hub/di/service_container.dart';
import 'package:psn.hotels.hub/data/services/synchronization_service.dart';

import '../models/entities_database/location_model.dart';

class LocationsRepository {
  final LocationApi locationApi = ApiContainer().locationApi;
  final FilesApi filesApi = ApiContainer().filesApi;
  final CategoryApi categoryApi = ApiContainer().categoryApi;
  DBManager db = DBManager();
  LocationsRepository();

  Future<List<LocationModel>> getLocations() async {
    try {
      var response = await locationApi.getAll();
      if (response != null && response.list != null) {
        return response.list!;
      } else {
        return [];
      }
    } catch (e) {
      throw e;
    }
  }

  // // Загрузит отели из ПСН БД
  // Future<void> getCategories() async {
  //   try {
  //     var response = await categoryApi.getAll();
  //     if (response != null && response.list != null) {
  //        await (await db.categoriesDao()).insertCategories(response.list!);

  //     }
  //   } catch (e) {
  //     throw e;
  //   }

  // }

  Future<void> startSinc() async {
    SinkService().startSynchronization();
  }

  Future<LocationModel?> getLocationFromLocalDB(int localId) async {
    try {
      return await (await db.locationsDao()).findLocationByLocalId(localId);
    } catch (e) {
      throw e;
    }
  }

  Future<int> addLocation(
      {required int hotelId, required LocationModel locationModel}) async {
    try {
      locationModel.hotelId = hotelId;
      locationModel.synced = false;
      locationModel.createdAt = DateTime.now().toIso8601String();

      int locationId =
          await (await db.locationsDao()).insertLocation(locationModel);
      return locationId;
    } catch (e) {
      throw e;
    }
  }

  Future<void> updateLocation({required LocationModel locationModel}) async {
    try {
      locationModel.synced = false;
      await (await db.locationsDao()).updateLocation(locationModel);
    } catch (e) {
      throw e;
    }
  }

  Future<void> deleteLocation(
      {required MyHotelModel hotelModel,
      required LocationModel locationModel}) async {
    try {
      locationModel.synced = false;
      locationModel.deleted = true;
      await (await db.locationsDao()).updateLocation(locationModel);
      var files = await (await db.filesDao())
              .findFilesByLocationId(locationModel.localId) ??
          [];
      for (var file in files) {
        file.deleted = true;
        file.synced = false;
        await (await db.filesDao()).updateFile(file.localId, file);
      }
      print("startSinc deleteLocation");
      ServiceContainer().sinkService.startSynchronization();
    } catch (e) {
      throw e;
    }
  }

  Future<void> removeAll() async {
    try {
      (await db.locationsDao()).clearLocationsTable();
    } catch (e) {
      throw e;
    }
  }

  // Future<void> addFile(
  //     {required LocationModel locationModel, required FileModel file}) async {
  //   file.synced = false;
  //   file.locationId = locationModel.id;
  //   await db.insertFile(file);
  //   //locationModel.getFiles.add(file);
  //   print("deleteLocation startSinc");
  //   ServiceContainer().sinkService.startSinc();
  //   await db.updateLocation(locationModel.id, locationModel);
  // }

  Future<void> addFile({required FileModel file}) async {
    file.synced = false;
    file.deleted = false;
    await (await db.filesDao()).insertFile(file);
  }

  Future<void> updateFile({required FileModel file}) async {
    file.synced = false;
    file.isEdited = false;
    await (await db.filesDao()).updateFile(file.localId, file);
  }

  // Future<void> deleteSelectedFiles(
  //     {required LocationModel locationModel, required FileModel file}) async {
  // file.synced = false;
  // file.deleted = true;
  // //await (await db.filesDao()).updateFile(file.localId, file);
  // debugPrint("deleteSelectedFiles startSinc");
  // //ServiceContainer().sinkService.startSinc();
  //}

  Future<List<LocationModel>> get allLocationsForSynchronization async {
    return await (await db.locationsDao()).getLocationsToSync();
  }
}
