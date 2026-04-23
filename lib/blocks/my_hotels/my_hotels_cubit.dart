import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:psn.hotels.hub/blocks/base_cubit/base_cubit.dart';
import 'package:psn.hotels.hub/blocks/list_cubit.dart';
import 'package:psn.hotels.hub/db/db_manager.dart';
import 'package:psn.hotels.hub/helpers/format_date.dart';
import 'package:psn.hotels.hub/models/entities_database/file_model.dart';
import 'package:psn.hotels.hub/models/entities_database/hotel_model.dart';
import 'package:psn.hotels.hub/models/entities_database/location_model.dart';
import 'package:psn.hotels.hub/models/entities_database/my_hotel_model.dart';
import 'package:psn.hotels.hub/services/service_container.dart';
import '../../repository/repository_container.dart';
import 'my_hotel_state.dart';

class MyHotelsCubit extends ListCubit<BaseQuery, MyHotelState> {
  final DBManager db = DBManager();
  StreamSubscription? _subscriptionSynchronization;
  late ScrollController scrollController;
  double scrollPosition = 0;

  MyHotelsCubit() : super(InitialState()) {
    scrollController = ScrollController();
    FirebaseCrashlytics.instance.setUserIdentifier(
        ServiceContainer().authService.user?.userName ?? "No auth");
    _subscriptionSynchronization =
        services.sinkService.syncMyHotelsObserver.stream.listen((id) {
      updateSingleHotel(id);
    });

    //init();
    //initial(query: BaseQuery());
  }

  @override
  Future<ListResult<MyHotelState>?> getModels({int page = 0}) async {
    try {
      const int limit = 6;
      int offset = page * limit;

      // 1. Получаем отели из БД
      var myHotels =
          await RepositoryContainer().myHotelRepository.getMyHotelsNotDeleted(
                search: query.search,
                limit: limit,
                offset: offset,
              );

      // 2. Считаем общее количество и последнюю страницу
      int totalCount = await RepositoryContainer()
          .myHotelRepository
          .getMyHotelsCount(search: query.search);

      int lastPage = (totalCount / limit).ceil() - 1;
      if (lastPage < 0) lastPage = 0;

      // 3. Собираем данные
      List<MyHotelState> newItems = [];
      for (var myHotelModel in myHotels) {
        List<FileModel> files = await getAllFilesOfMyHotel(myHotelModel);
        double percentUploaded =
            await getPercentLoadedOfAllFilesOfMyHotel(myHotelModel);
        List<String> countryAndResort =
            await getCountryAndResortOfMyHotel(myHotelModel);

        newItems.add(MyHotelState(
          base: myHotelModel,
          files: files,
          percentUploaded: percentUploaded,
          country: countryAndResort[0],
          resort: countryAndResort[1],
        ));
      }

      // Возвращаем результат обернутым в ListResult
      return ListResult(models: newItems, lastPage: lastPage);
    } catch (e) {
      catchError(e);
      return null; // Теперь возвращаем null в случае ошибки, что допустимо для типа ?
    }
  }

  @override
  int get modelsLength => models.length;

  Future<void> updateSingleHotel(int hotelId) async {
    try {
      var dao = await db.myHotelsDao();
      var hotelMap = await dao.findMyHotelById(hotelId);

      if (hotelMap != null) {
        var myHotelModel = MyHotelModel.fromMap(hotelMap);

        List<FileModel> files = await getAllFilesOfMyHotel(myHotelModel);
        double percentUploaded =
            await getPercentLoadedOfAllFilesOfMyHotel(myHotelModel);
        List<String> countryAndResort =
            await getCountryAndResortOfMyHotel(myHotelModel);

        var updatedState = MyHotelState(
          base: myHotelModel,
          files: files,
          percentUploaded: percentUploaded,
          country: countryAndResort[0],
          resort: countryAndResort[1],
        );

        insert(model: updatedState);
      }
    } catch (e) {
      catchError(e);
    }
  }

  @override
  Future<void> close() {
    _subscriptionSynchronization?.cancel();
    scrollController.dispose();
    return super.close();
  }

  Future<List<String>> getCountryAndResortOfMyHotel(
      MyHotelModel? myHotelModel) async {
    return await myHotelModel?.getCountryAndResort(db) ?? [];
  }

  Future<double> getPercentLoadedOfAllFilesOfMyHotel(
      MyHotelModel? myHotelModel) async {
    if (myHotelModel == null) return 0.0;
    return await myHotelModel.getPercentLoadedOfAllFilesOfMyHotel(db);
  }

  Future<List<LocationModel>> getAllLocationsOfMyHotel(
      MyHotelModel? myHotelModel) async {
    if (myHotelModel == null) return [];
    return await myHotelModel.getLocations(db) ?? [];
  }

  Future<List<FileModel>> getAllFilesOfMyHotel(
      MyHotelModel? myHotelModel) async {
    if (myHotelModel == null) return [];
    return await myHotelModel.getAllFiles(db);
  }

  Future<MyHotelModel?> addMyHotel({required HotelModel hotel}) async {
    try {
      MyHotelModel? myNewHotel = await RepositoryContainer()
          .myHotelRepository
          .addMyHotel(hotel: hotel);

      var newState = MyHotelState(
        base: myNewHotel,
        files: [],
        percentUploaded: -1,
        country: hotel.country,
        resort: hotel.resort,
      );
      insert(model: newState, byIndex: 0);

      return myNewHotel;
    } catch (e) {
      catchError(e);
      return null;
    }
  }

  Future<void> removeHotel({required MyHotelModel myHotel}) async {
    try {
      await RepositoryContainer()
          .myHotelRepository
          .removeHotel(myHotel: myHotel);

      // Находим MyHotelState в текущем списке моделей и удаляем его
      // var modelToRemove =
      //models.firstWhereOrNull((m) => m.base.id == myHotel.id);
      // Находим MyHotelState в текущем списке моделей по ID
      var modelToRemove = modelById(id: myHotel.id);
      if (modelToRemove != null) {
        remove(model: modelToRemove);
        updateList(); // Обновляем UI
      }
    } catch (e) {
      catchError(e);
    }
  }

  @override
  sortIfNeeded() {
    super.sort((a, b) {
      final dateA = stringToDate(a.base.createdAt);
      final dateB = stringToDate(b.base.createdAt);
      if (dateA != null && dateB != null) {
        return dateB.compareTo(dateA);
      }
      return 0;
    });
  }
}
