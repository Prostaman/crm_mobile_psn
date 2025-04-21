import 'package:psn.hotels.hub/blocks/base_cubit/base_cubit.dart';

import 'package:psn.hotels.hub/db/db_manager.dart';
import 'package:psn.hotels.hub/models/entities_database/file_model.dart';
import 'package:psn.hotels.hub/models/entities_database/location_model.dart';
import 'package:psn.hotels.hub/models/entities_database/my_hotel_model.dart';
import 'package:psn.hotels.hub/repository/repository_container.dart';

class EditHotelCubit extends BaseCubit {
  final DBManager db;
  MyHotelModel myHotel;

  EditHotelCubit({required this.myHotel, required this.db}) : super(InitialState());

  Future<void> updateHotel() async {
    try {
      emit(LoadingState());
      myHotel = await RepositoryContainer().myHotelRepository.updateMyHotel(model: myHotel);
      emit(SuccessModelState(model: myHotel));
    } catch (e) {
      catchError(e);
    }
  }

  Future<List<LocationModel>?> getLocations() async {
    final locationsData = await (await db.locationsDao()).findLocationsByHotelId(myHotel.id) ?? [];
    // Фильтруем список, чтобы оставить только не удаленные локации
    final locations = locationsData.map((locationMap) => LocationModel.fromMap(locationMap)).where((location) => location.deleted == false).toList();

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

  Future<double> getPercentOfLoadedFilesOfLocationByLocationId(int locationId) async {
    var x = await findFilesByLocationId(locationId);
    if (x.isNotEmpty) {
      var loaded = x.where((element) => element.synced == true && element.deleted == false).length;
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
    emit(InitialState());
    emit(SuccessModelState(model: myHotel));
  }

  Future<void> deleteLocation({required LocationModel locationModel}) async {
    try {
      emit(LoadingState());
      await RepositoryContainer().locationsRepository.deleteLocation(hotelModel: myHotel, locationModel: locationModel);
      emit(SuccessModelState(model: myHotel));
    } catch (e) {
      catchError(e);
    }
  }
}
