import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:psn.hotels.hub/data/datasources/local/db/dao/hotels_dao.dart';
import 'package:psn.hotels.hub/data/datasources/local/db/db_manager.dart';
import 'package:psn.hotels.hub/data/datasources/remote/api/api_container.dart';
import 'package:psn.hotels.hub/data/datasources/remote/api/hotel_api.dart';
import 'package:psn.hotels.hub/data/repository/hotel_list_repository.dart';
import 'package:psn.hotels.hub/infrastructure/shared_preferences_utils.dart';
import 'package:psn.hotels.hub/data/models/response_models/hotels_response.dart';

class MockApiContainer extends Mock implements ApiContainer {}

class MockHotelApi extends Mock implements HotelApi {}

class MockDBManager extends Mock implements DBManager {}

class MockHotelsDao extends Mock implements HotelsDao {}

class MockSharedPrefUtils extends Mock implements SharedPrefUtils {}

void main() {
  late HotelListRepository repository;
  late MockApiContainer mockApiContainer;
  late MockHotelApi mockHotelApi;
  late MockDBManager mockDBManager;
  late MockHotelsDao mockHotelsDao;
  late MockSharedPrefUtils mockSharedPrefUtils;

  setUp(() {
    mockApiContainer = MockApiContainer();
    mockHotelApi = MockHotelApi();
    mockDBManager = MockDBManager();
    mockHotelsDao = MockHotelsDao();
    mockSharedPrefUtils = MockSharedPrefUtils();

    ApiContainer.instance = mockApiContainer;
    DBManager.instance = mockDBManager;
    SharedPrefUtils.instance = mockSharedPrefUtils;

    when(() => mockApiContainer.hotelApi).thenReturn(mockHotelApi);
    when(() => mockDBManager.hotelsDao())
        .thenAnswer((_) async => mockHotelsDao);
    when(() => mockSharedPrefUtils.init()).thenAnswer((_) async => {});

    repository = HotelListRepository();
  });

  group('HotelListRepository Tests', () {
    test('downloadAllHotels возвращает true при успешной загрузке', () async {
      final response = HotelsResponse(success: true, list: []);

      when(() => mockSharedPrefUtils.getValue(any(), any())).thenReturn("");
      when(() => mockHotelApi.getAll(any(), any()))
          .thenAnswer((_) async => response);
      when(() => mockSharedPrefUtils.setValue(any(), any())).thenReturn(null);

      final result = await repository.downloadAllHotels();

      expect(result, true);
      verify(() => mockHotelApi.getAll(any(), false)).called(1);
      verify(() => mockSharedPrefUtils.setValue("kLastUpdated", any()))
          .called(1);
    });

    test('downloadAllHotels возвращает false после 4 неудачных попыток',
        () async {
      final response = HotelsResponse(success: false, list: []);

      when(() => mockSharedPrefUtils.getValue(any(), any())).thenReturn("");
      when(() => mockHotelApi.getAll(any(), any()))
          .thenAnswer((_) async => response);

      final result = await repository.downloadAllHotels();

      expect(result, false);
      verify(() => mockHotelApi.getAll(any(), false)).called(4);
    });
  });
}
