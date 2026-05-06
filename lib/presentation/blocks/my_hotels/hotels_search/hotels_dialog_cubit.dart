import 'package:psn.hotels.hub/presentation/blocks/base_cubit/base_cubit.dart';
import 'package:psn.hotels.hub/presentation/blocks/my_hotels/hotels_search/hotel_search_state.dart';
import 'package:psn.hotels.hub/presentation/blocks/list_cubit.dart';
import 'package:psn.hotels.hub/data/models/entities_database/hotel_model.dart';
import 'package:psn.hotels.hub/data/repository/repository_container.dart';

class HotelsDialogCubit extends ListCubit<BaseQuery, HotelSearchState> {
  int selectedHotelID = -1;

  HotelsDialogCubit() : super(InitialState()) {
    query = BaseQuery();
  }

  @override
  Future<ListResult<HotelSearchState>?> getModels({int page = 0}) async {
    try {
      if (page == 0) selectedHotelID = -1;

      const int limit = 20;
      int offset = page * limit;

      List<HotelModel> hotels = await RepositoryContainer()
          .hotelListRepository
          .getHotelsBySearchTextAndSortedByDistanceRepository(
            limit: limit,
            offset: offset,
            search: query.search,
          );

      int totalCount = await RepositoryContainer()
          .hotelListRepository
          .getHotelsCountBySearchText(search: query.search);

      int lastPage = (totalCount / limit).ceil() - 1;
      if (lastPage < 0) lastPage = 0;

      List<HotelSearchState> newItems = hotels.map((hotel) {
        return HotelSearchState(
          id: hotel.id,
          name: hotel.name,
          country: hotel.country,
          resort: hotel.resort,
          isSelected: hotel.id == selectedHotelID,
        );
      }).toList();

      return ListResult(models: newItems, lastPage: lastPage);
    } catch (e) {
      catchError(e);
      return null;
    }
  }

  Future<void> selectHotel(int index) async {
    try {
      selectedHotelID = models[index].id;
      for (int i = 0; i < models.length; i++) {
        models[i] = models[i].copyWith(isSelected: i == index);
      }
      updateList(models);
    } catch (e) {
      catchError(e);
    }
  }
}
