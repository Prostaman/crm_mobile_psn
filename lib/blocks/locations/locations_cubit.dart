import 'dart:async';

import 'package:flutter/material.dart';
import 'package:psn.hotels.hub/blocks/base_cubit/base_cubit.dart';

import 'package:psn.hotels.hub/db/db_manager.dart';
import 'package:psn.hotels.hub/models/entities_database/file_model.dart';
import 'package:psn.hotels.hub/models/entities_database/location_model.dart';
import 'package:psn.hotels.hub/models/entities_database/my_hotel_model.dart';
import 'package:psn.hotels.hub/repository/repository_container.dart';

class LocationsCubit extends BaseCubit {
  final DBManager db;
  MyHotelModel myHotel;
  StreamSubscription? _subscriptionSinc;
  LocationsState locationsData = LocationsState(
    locations: [],
    listOflistOfFiles: [],
    listOfPercentLoaded: [],
    descriptionCategories: [],
    allFilesLength: 0,
    percentOfLoadingAllFiles: 0.0,
    percentLoaded: 0.0,
  );

  late ScrollController scrollController;
  double scrollPosition = 0;

  LocationsCubit({
    required this.myHotel,
    required this.db,
  }) : super(InitialState()) {
    _subscriptionSinc =
        services.sinkService.syncLocationsObserver.stream.listen((item) {
      refresh();
    });
    init();
  }

  Future<void> init() async {
    emit(LoadingState());
    try {
      locationsData = await getAllData();
      emit(SuccessModelState<LocationsState>(
        model: locationsData,
      ));
    } catch (e) {
      catchError(e);
      emit(ErrorState(error: e.toString()));
    }
  }

  @override
  Future<void> close() {
    _subscriptionSinc?.cancel();
    return super.close();
  }

  Future<void> updateHotel() async {
    try {
      emit(LoadingState());
      myHotel = await RepositoryContainer()
          .myHotelRepository
          .updateMyHotel(model: myHotel);

      emit(SuccessModelState(model: myHotel));
    } catch (e) {
      catchError(e);
    }
  }

  Future<List<LocationModel>?> getLocations() async {
    final locationsData =
        await (await db.locationsDao()).findLocationsByHotelId(myHotel.id) ??
            [];
    // Фильтруем список, чтобы оставить только не удаленные локации
    final locations = locationsData
        .map((locationMap) => LocationModel.fromMap(locationMap))
        .where((location) => location.deleted == false)
        .toList();

    return locations;
  }

  Future<String> findDescriptionOfCategoryById(int id) async {
    var category = (await (await db.categoriesDao()).findCategoryById(id));
    if (category != null) {
      return category.description;
    } else {
      return 'Без категории';
    }
  }

  Future<List<FileModel>> findFilesByLocationId(int locationId) async {
    return await (await db.filesDao()).findFilesByLocationId(locationId) ?? [];
  }

  Future<double> getPercentOfLoadedFilesOfLocationByLocationId(
      int locationId) async {
    var x = await findFilesByLocationId(locationId);
    if (x.isNotEmpty) {
      var loaded = x
          .where(
              (element) => element.synced == true && element.deleted == false)
          .length;
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

  Future<double> getPercentLoadedOfAllFilesOfMyHotel() async {
    return await myHotel.getPercentLoadedOfAllFilesOfMyHotel(db);
  }

  Future<void> refresh() async {
    scrollController = ScrollController(initialScrollOffset: scrollPosition);
    await init();
  }

  Future<void> deleteLocation({required LocationModel locationModel}) async {
    try {
      emit(LoadingState());
      await RepositoryContainer()
          .locationsRepository
          .deleteLocation(hotelModel: myHotel, locationModel: locationModel);
      // emit(SuccessModelState<LocationsState>(
      //   model: locationsData,
      // )); почему-то лучше работает без этого
    } catch (e) {
      catchError(e);
    }
  }

  Future<LocationsState> getAllData() async {
    final locations = (await getLocations() ?? []).reversed.toList();
    double percentLoaded = await getPercentLoadedOfAllFilesOfMyHotel();

    List<List<FileModel>> listOflistOfFiles = [];
    List<double> listOfPercentLoaded = [];
    List<String> descriptionCategories = [];
    int allFilesLoaded = 0;
    int allFilesLength = 0;

    for (var location in locations) {
      descriptionCategories
          .add(await findDescriptionOfCategoryById(location.idCategory));
      var files = await findFilesByLocationId(location.localId);
      var notDeletedFiles = files.where((f) => !f.deleted).toList();
      listOflistOfFiles.add(notDeletedFiles);

      allFilesLength += notDeletedFiles.length;
      allFilesLoaded += notDeletedFiles.where((f) => f.synced).length;

      listOfPercentLoaded.add(
          await getPercentOfLoadedFilesOfLocationByLocationId(
              location.localId));
    }

    double percentOfLoadingAllFiles =
        allFilesLength == 0 ? -1 : 100 * allFilesLoaded / allFilesLength;

    return LocationsState(
      locations: locations,
      listOflistOfFiles: listOflistOfFiles,
      listOfPercentLoaded: listOfPercentLoaded,
      descriptionCategories: descriptionCategories,
      allFilesLength: allFilesLength,
      percentOfLoadingAllFiles: percentOfLoadingAllFiles,
      percentLoaded: percentLoaded,
    );
  }
}

class LocationsState {
  final List<LocationModel> locations;
  final List<List<FileModel>> listOflistOfFiles;
  final List<double> listOfPercentLoaded;
  final List<String> descriptionCategories;
  final int allFilesLength;
  final double percentOfLoadingAllFiles;
  final double percentLoaded;

  LocationsState({
    required this.locations,
    required this.listOflistOfFiles,
    required this.listOfPercentLoaded,
    required this.descriptionCategories,
    required this.allFilesLength,
    required this.percentOfLoadingAllFiles,
    required this.percentLoaded,
  });
}
