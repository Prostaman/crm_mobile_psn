import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:psn.hotels.hub/presentation/blocks/base_cubit/base_cubit.dart';
import 'package:psn.hotels.hub/presentation/blocks/list_cubit.dart';
import 'package:psn.hotels.hub/presentation/blocks/locations/states/location_state.dart';

import 'package:psn.hotels.hub/data/datasources/local/db/db_manager.dart';
import 'package:psn.hotels.hub/data/models/entities_database/file_model.dart';
import 'package:psn.hotels.hub/data/models/entities_database/location_model.dart';
import 'package:psn.hotels.hub/data/models/entities_database/my_hotel_model.dart';
import 'package:psn.hotels.hub/data/repository/repository_container.dart';

import 'states/locations_screen_state.dart';

class LocationsCubit extends ListCubit<BaseQuery, LocationState> {
  late final DBManager db;
  MyHotelModel myHotel;
  StreamSubscription? _subscriptionLocationsSynchronization;

  // Данные сводки по отелю
  int allFilesLength = 0;
  double percentLoadedFiles = -1;

  LocationsCubit({required this.myHotel}) : super(InitialState()) {
    db = DBManager();
    query = BaseQuery();
    _subscriptionLocationsSynchronization =
        services.sinkService.syncLocationsObserver.stream.listen((id) async {
      if (id == -1) {
        allFilesLength = 0;
        percentLoadedFiles = 0;
        reload();
      } else {
        await updateHotelSummary();
        updateSingleLocation(id);
      }
    });
  }

  @override
  Future<void> initial({required BaseQuery query}) async {
    await updateHotelSummary();
    super.initial(query: query);
  }

  Future<void> updateHotelSummary() async {
    final dao = await db.filesDao();
    final stats = await dao.getNotDeletedFilesCountByHotelId(myHotel.id);
    allFilesLength = stats.total;
    percentLoadedFiles =
        stats.total == 0 ? -1 : (100 * stats.synced / stats.total);
  }

  @override
  Future<void> updateList(List<LocationState> newList) async {
    debugPrint('LocationsList updateList');
    await updateHotelSummary();
    emit(LocationsListSuccessState(
      models: List.from(newList),
      myHotel: myHotel,
      allFilesLength: allFilesLength,
      percentLoadedFiles: percentLoadedFiles,
    ));
  }

  Future<void> updateSingleLocation(int localId) async {
    try {
      var dao = await db.locationsDao();
      LocationModel? location = await dao.findLocationByLocalId(localId);

      if (location != null) {
        final categoryDesc =
            await findDescriptionOfCategoryById(location.idCategory);
        final files = await findNotDeletedFilesByLocationId(location.localId);
        final percent = await getPercentOfLoadedFilesOfLocationByLocationId(
            location.localId);

        var updatedState = LocationState(
          location: location,
          files: files,
          percentLoaded: percent,
          categoryDescription: categoryDesc,
        );

        insert(model: updatedState);
      }
    } catch (e) {
      catchError(e);
    }
  }

  @override
  Future<ListResult<LocationState>?> getModels({int page = 0}) async {
    try {
      const int limit = 12;
      int offset = page * limit;

      // 1. Получаем локации из БД
      final locationsData = await (await db.locationsDao())
              .findNotDeletedLocationsByHotelId(myHotel.id,
                  limit: limit, offset: offset) ??
          [];

      final locations = locationsData
          .map((locationMap) => LocationModel.fromMap(locationMap))
          .where((location) => location.deleted == false)
          .toList();

      // 2. Считаем общее количество и последнюю страницу
      int totalCount = await (await db.locationsDao())
          .getLocationsCountByHotelId(myHotel.id);
      int lastPage = (totalCount / limit).ceil() - 1;
      if (lastPage < 0) lastPage = 0;

      // 3. Собираем сводные данные по отелю
      //await _updateHotelSummary();

      // 4. Преобразуем в LocationState
      List<LocationState> items = [];
      for (var location in locations) {
        final categoryDesc =
            await findDescriptionOfCategoryById(location.idCategory);
        final files = await findNotDeletedFilesByLocationId(location.localId);
        final percent = await getPercentOfLoadedFilesOfLocationByLocationId(
            location.localId);

        items.add(LocationState(
          location: location,
          files: files,
          percentLoaded: percent,
          categoryDescription: categoryDesc,
        ));
      }

      return ListResult(models: items, lastPage: lastPage);
    } catch (e) {
      catchError(e);
      return null;
    }
  }

  @override
  Future<void> close() {
    _subscriptionLocationsSynchronization?.cancel();
    return super.close();
  }

  Future<void> updateDescriptionMyHotel(String description) async {
    try {
      myHotel = myHotel.copyWith(description: description);
      myHotel = await RepositoryContainer()
          .myHotelRepository
          .updateMyHotel(model: myHotel);
      emit((state as LocationsListSuccessState).copyWith(myHotel: myHotel));
    } catch (e) {
      catchError(e);
    }
  }

  Future<String> findDescriptionOfCategoryById(int id) async {
    var category = (await (await db.categoriesDao()).findCategoryById(id));
    if (category != null) {
      return category.description;
    } else {
      return 'Без категории';
    }
  }

  Future<List<FileModel>> findNotDeletedFilesByLocationId(
      int locationId) async {
    return await (await db.filesDao())
            .findNotDeletedFilesByLocationId(locationId) ??
        [];
  }

  Future<double> getPercentOfLoadedFilesOfLocationByLocationId(
      int locationId) async {
    var x = await findNotDeletedFilesByLocationId(locationId);
    if (x.isNotEmpty) {
      var loaded = x.where((element) => element.synced == true).length;
      var i = (100 / x.length) * loaded;
      if (i > 100) {
        return 100;
      } else if (i < 0) {
        return 0.0;
      } else {
        return i;
      }
    }
    return -1;
  }

  Future<void> deleteLocation({required LocationModel locationModel}) async {
    try {
      emit(LoadingState());
      await RepositoryContainer()
          .locationsRepository
          .deleteLocation(hotelModel: myHotel, locationModel: locationModel);

      var itemToRemove = models
          .where((m) => m.location.localId == locationModel.localId)
          .first;
      remove(model: itemToRemove);

      updateList(models);
    } catch (e) {
      catchError(e);
    }
  }
}
