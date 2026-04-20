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

class MyHotelsCubit extends ListCubit<BaseQuery, MyHotelModel> {
  final DBManager db = DBManager();
  StreamSubscription? _subscriptionSinc;
  late ScrollController scrollController;
  double scrollPosition = 0;
  List<MyHotelState> myHotelsUI = [];

  MyHotelsCubit() : super(InitialState()) {
    FirebaseCrashlytics.instance.setUserIdentifier(
        ServiceContainer().authService.user?.userName ?? "No auth");
    _subscriptionSinc = services.sinkService.syncSuccess.stream.listen((item) {
      refresh();
    });
    init();
  }

  Future<void> init() async {
    emit(LoadingState());
    try {
      myHotelsUI.clear();
      // 1. Отримуємо всі готелі
      var myHotels =
          await RepositoryContainer().myHotelRepository.getMyHotels();
      // 2. Створюємо список MyHotelUI
      for (var myHotelModel in myHotels) {
        // Асинхронно отримуємо додаткові дані
        List<FileModel> files = await getAllFilesOfMyHotel(myHotelModel);
        List<LocationModel> locations =
            await getAllLocationsOfMyHotel(myHotelModel);
        double percentUploaded =
            await getPercentLoadedOfAllFilesOfMyHotel(myHotelModel);
        List<String> countryAndResort =
            await getCountryAndResortOfMyHotel(myHotelModel);
        // 3. Створюємо UI-модель
        MyHotelState hotelUI = MyHotelState(
          base: myHotelModel,
          files: files,
          locations: locations,
          percentUploaded: percentUploaded,
          country: countryAndResort[0],
          resort: countryAndResort[1],
        );

        myHotelsUI.add(hotelUI);
      }
      debugPrint(" myHotelsUI length:${myHotelsUI.length}");

      // 4. Відправляємо стан успіху
      debugPrint(
          "Emit state: ${SuccessListState<MyHotelState>(models: myHotelsUI, date: DateTime.now())}");
      emit(SuccessListState<MyHotelState>(
        models: myHotelsUI,
      ));
    } catch (e) {
      catchError(e);
      emit(ErrorState(error: e.toString()));
    }
  }

  @override
  int get modelsLenght => myHotelsUI.length;

  @override
  Future<void> refresh() async {
    scrollController = ScrollController(initialScrollOffset: scrollPosition);
    await init();
  }

  @override
  Future<void> close() {
    _subscriptionSinc?.cancel();
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

  @override
  Future<void> getModels({int page = 0}) async {
    // try {
    //   emit(LoadingState());
    //   var hotels = await RepositoryContainer().myHotelRepository.getMyHotels();
    //   setResponse(data: hotels, page: page, lastPage: page);
    // } catch (e) {
    //   catchError(e);
    // }
  }

  Future<void> addHotel({required HotelModel hotel}) async {
    try {
      await RepositoryContainer().myHotelRepository.addMyHotel(hotel: hotel);
      await super.reload();
    } catch (e) {
      catchError(e);
    }
  }

  Future<void> removeHotel({required MyHotelModel myHotel}) async {
    try {
      emit(LoadingState());
      await RepositoryContainer()
          .myHotelRepository
          .removeHotel(myHotel: myHotel);
      await super.reload();
    } catch (e) {
      catchError(e);
    }
  }

  @override
  sortIfNeeded() {
    super.sort((a, b) {
      final dateA = stringToDate(a.createdAt);
      final dateB = stringToDate(b.createdAt);
      // Add null checks before invoking compareTo
      if (dateA != null && dateB != null) {
        return dateB.compareTo(dateA);
      } else {
        // Handle the case where either dateA or dateB is null
        // You might want to define a default behavior or handle it accordingly
        return 0; // or any other default value or logic
      }
    });
  }
}

class MyHotelState {
  final MyHotelModel base; // зберігаємо всю базову модель
  final List<FileModel> files;
  final List<LocationModel> locations;
  final double percentUploaded;
  final String country;
  final String resort;

  MyHotelState({
    required this.base,
    required this.files,
    required this.locations,
    required this.percentUploaded,
    required this.country,
    required this.resort,
  });

// int get id => base.id;
// String? get description => base.description;
// String get name => base.name;
// і так далі для інших полів, якщо потрібно
}
