import 'categories_repository.dart';
import 'locations_repository.dart';
import 'my_hotels_repository.dart';
import 'hotel_list_repository.dart';

// класс в котором создаются репозитории всех объектов
class RepositoryContainer {
  static final RepositoryContainer _singleton = RepositoryContainer._internal();
  factory RepositoryContainer() {
    return _singleton;
  }

  late MyHotelRepository _myHotelRepository;
  MyHotelRepository get myHotelRepository {
    return _myHotelRepository;
  }

  late HotelListRepository _hotelListRepository;
  HotelListRepository get hotelListRepository {
    return _hotelListRepository;
  }

  late HotelLocationsRepository _locationsRepository;
  HotelLocationsRepository get locationsRepository {
    return _locationsRepository;
  }

  late CategoriesRepository _categoriesRepository;
  CategoriesRepository get categoriesRepository {
    return _categoriesRepository;
  }

  RepositoryContainer._internal() {
    _myHotelRepository = MyHotelRepository();
    _hotelListRepository = HotelListRepository();
    _locationsRepository = HotelLocationsRepository();
    _categoriesRepository = CategoriesRepository();
  }
}
