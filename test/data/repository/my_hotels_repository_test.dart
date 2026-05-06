import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:psn.hotels.hub/data/datasources/local/db/dao/my_hotels_dao.dart';
import 'package:psn.hotels.hub/data/datasources/local/db/db_manager.dart';
import 'package:psn.hotels.hub/data/datasources/remote/api/api_container.dart';
import 'package:psn.hotels.hub/data/datasources/remote/api/hotel_api.dart';
import 'package:psn.hotels.hub/data/repository/my_hotels_repository.dart';
import 'package:psn.hotels.hub/data/models/entities_database/hotel_model.dart';
import 'package:psn.hotels.hub/data/models/entities_database/my_hotel_model.dart';

class MockApiContainer extends Mock implements ApiContainer {}

class MockHotelApi extends Mock implements HotelApi {}

class MockDBManager extends Mock implements DBManager {}

class MockMyHotelsDao extends Mock implements MyHotelsDao {}

// Для mocktail нужно зарегистрировать дефолтное значение, если мы используем any() для кастомных типов
class MyHotelModelFake extends Fake implements MyHotelModel {}

void main() {
  late MyHotelRepository repository;
  late MockApiContainer mockApiContainer;
  late MockHotelApi mockHotelApi;
  late MockDBManager mockDBManager;
  late MockMyHotelsDao mockMyHotelsDao;

  setUpAll(() {
    registerFallbackValue(MyHotelModelFake());
  });

  setUp(() {
    mockApiContainer = MockApiContainer();
    mockHotelApi = MockHotelApi();
    mockDBManager = MockDBManager();
    mockMyHotelsDao = MockMyHotelsDao();

    // Настраиваем моки синглтонов
    when(() => mockApiContainer.hotelApi).thenReturn(mockHotelApi);
    ApiContainer.instance = mockApiContainer;

    when(() => mockDBManager.myHotelsDao())
        .thenAnswer((_) async => mockMyHotelsDao);
    DBManager.instance = mockDBManager;

    repository = MyHotelRepository();
  });

  group('MyHotelRepository Tests', () {
    test('getMyHotelsCount должен возвращать количество из DAO', () async {
      when(() => mockMyHotelsDao.getMyHotelsCount(search: any(named: 'search')))
          .thenAnswer((_) async => 42);

      final count = await repository.getMyHotelsCount(search: 'query');

      expect(count, 42);
      verify(() => mockMyHotelsDao.getMyHotelsCount(search: 'query')).called(1);
    });

    test('addMyHotel должен вставлять новый отель, если он не найден в БД',
        () async {
      final hotel = HotelModel(
          id: 101,
          name: 'Ocean View',
          lat: 1.0,
          long: 2.0,
          active: true,
          cid: '123',
          country: 'Ukraine',
          resort: 'Odesa');

      when(() => mockMyHotelsDao.findMyHotelById(101))
          .thenAnswer((_) async => null);
      when(() => mockMyHotelsDao.insertMyHotel(any()))
          .thenAnswer((_) async => {});

      final result = await repository.addMyHotel(hotel: hotel);

      expect(result.id, 101);
      expect(result.name, 'Ocean View');
      verify(() => mockMyHotelsDao.insertMyHotel(any())).called(1);
    });

    test('addMyHotel должен обновлять существующий отель, если он найден',
        () async {
      final hotel = HotelModel(
          id: 101,
          name: 'Ocean View',
          lat: 1.0,
          long: 2.0,
          active: true,
          cid: '123',
          country: 'Ukraine',
          resort: 'Odesa');

      final existingMap = {
        'id': 101,
        'name': 'Old Name',
        'description': 'Some desc',
        'createdAt': '2023-01-01',
        'updatedAt': '2023-01-01',
        'synced': 1,
        'deleted': 1,
        'pathOfProfilePhoto': '',
        'profilePhotoIsChanged': 0,
        'country': 'Ukraine',
        'resort': 'Odesa'
      };

      when(() => mockMyHotelsDao.findMyHotelById(101))
          .thenAnswer((_) async => existingMap);
      when(() => mockMyHotelsDao.updateMyHotel(any(), any()))
          .thenAnswer((_) async => {});

      final result = await repository.addMyHotel(hotel: hotel);

      expect(result.id, 101);
      expect(result.deleted, false);
      verify(() => mockMyHotelsDao.updateMyHotel(101, any())).called(1);
    });

    test('removeAll должен очищать таблицу через DAO', () async {
      when(() => mockMyHotelsDao.clearMyHotelsTable())
          .thenAnswer((_) async => {});

      await repository.removeAll();

      verify(() => mockMyHotelsDao.clearMyHotelsTable()).called(1);
    });
  });
}
