import 'package:psn.hotels.hub/blocks/base_cubit/base_cubit.dart';
import 'package:psn.hotels.hub/blocks/list_cubit.dart';
import 'package:psn.hotels.hub/helpers/format_date.dart';
import 'package:psn.hotels.hub/models/entities_database/hotel_model.dart';
import 'package:psn.hotels.hub/models/entities_database/my_hotel_model.dart';
import '../../repository/repository_container.dart';

class MyHotelsCubit extends ListCubit<BaseQuery, MyHotelModel> {
  MyHotelsCubit() : super(InitialState());

  @override
  Future<void> getModels({int page = 0}) async {
    try {
      emit(LoadingState());
      var hotels = await RepositoryContainer().myHotelRepository.getHotels();
      setResponse(data: hotels, page: page, lastPage: page);
    } catch (e) {
      catchError(e);
    }
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
      await RepositoryContainer().myHotelRepository.removeHotel(myHotel: myHotel);
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
