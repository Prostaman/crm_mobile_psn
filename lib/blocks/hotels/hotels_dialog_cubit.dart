import 'package:psn.hotels.hub/blocks/base_cubit/base_cubit.dart';
import 'package:psn.hotels.hub/blocks/list_cubit.dart';
import 'package:psn.hotels.hub/blocks/local_search_cubit_mixin.dart';
import 'package:psn.hotels.hub/models/entities_database/hotel_model.dart';
import 'package:psn.hotels.hub/models/response_models/base_model.dart';

import '../../repository/repository_container.dart';

class HotelsDialogCubit extends ListCubit<BaseQuery, HotelModel>
    with LocalSearchCubitMixin<HotelModel> {
  // кол-во файлов для отображения
  final int limit = 100;

  HotelsDialogCubit() : super(InitialState()) {
    query = BaseQuery();
  }

  Future<void> clear() async {
    removeAll();
  }

  @override
  Future<ListResult<HotelModel>?> getModels({int page = 0}) async {
    return null;
  }

  @override
  Future<void> addAll({List<HotelModel>? models}) async {
    await cubit.removeAll();
    var list = models?.take(limit).toList() ?? [];
    await super.addAll(models: list);
  }

  @override
  Future<void> search() async {
    cubit.removeAll();
    var searchHotels = await RepositoryContainer()
        .hotelListRepository
        .getHotelsBySearchTextAndSortedByDistanceRepository(
            limit, query.search);
    // var searched = saved.where((element) => element.name.toLowerCase().contains(query.search.toLowerCase())).toList();
    // cubit.addAll(models: searched);
    await cubit.addAll(models: searchHotels);
  }

  Future<List<HotelModel>> getNearestHotels() async {
    return await RepositoryContainer()
        .hotelListRepository
        .getHotelsBySearchTextAndSortedByDistanceRepository(limit, "");
  }

  @override
  List<HotelModel> saved = [];

  @override
  ListCubit<BaseQuery, BaseModel> get cubit => this;
}
