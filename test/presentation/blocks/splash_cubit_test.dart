import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:psn.hotels.hub/data/datasources/local/db/dao/hotels_dao.dart';
import 'package:psn.hotels.hub/data/datasources/local/db/db_manager.dart';
import 'package:psn.hotels.hub/data/repository/categories_repository.dart';
import 'package:psn.hotels.hub/data/repository/hotel_list_repository.dart';
import 'package:psn.hotels.hub/data/repository/repository_container.dart';
import 'package:psn.hotels.hub/data/services/auth_service.dart';
import 'package:psn.hotels.hub/di/service_container.dart';
import 'package:psn.hotels.hub/presentation/blocks/splash/splash_cubit.dart';

class MockServiceContainer extends Mock implements ServiceContainer {}

class MockAuthService extends Mock implements AuthService {}

class MockRepositoryContainer extends Mock implements RepositoryContainer {}

class MockHotelListRepository extends Mock implements HotelListRepository {}

class MockCategoriesRepository extends Mock implements CategoriesRepository {}

class MockDBManager extends Mock implements DBManager {}

class MockHotelsDao extends Mock implements HotelsDao {}

void main() {
  late SplashCubit splashCubit;
  late MockServiceContainer mockServiceContainer;
  late MockAuthService mockAuthService;
  late MockRepositoryContainer mockRepositoryContainer;
  late MockHotelListRepository mockHotelListRepository;
  late MockCategoriesRepository mockCategoriesRepository;
  late MockDBManager mockDBManager;
  late MockHotelsDao mockHotelsDao;

  late StreamController<bool> hotelLoadingController;
  late StreamController<int> hotelInsertingController;
  late StreamController<bool> categoriesLoadingController;

  setUp(() {
    mockServiceContainer = MockServiceContainer();
    mockAuthService = MockAuthService();
    mockRepositoryContainer = MockRepositoryContainer();
    mockHotelListRepository = MockHotelListRepository();
    mockCategoriesRepository = MockCategoriesRepository();
    mockDBManager = MockDBManager();
    mockHotelsDao = MockHotelsDao();

    hotelLoadingController = StreamController<bool>.broadcast();
    hotelInsertingController = StreamController<int>.broadcast();
    categoriesLoadingController = StreamController<bool>.broadcast();

    ServiceContainer.instance = mockServiceContainer;
    RepositoryContainer.instance = mockRepositoryContainer;
    DBManager.instance = mockDBManager;

    when(() => mockServiceContainer.authService).thenReturn(mockAuthService);
    when(() => mockRepositoryContainer.hotelListRepository)
        .thenReturn(mockHotelListRepository);
    when(() => mockRepositoryContainer.categoriesRepository)
        .thenReturn(mockCategoriesRepository);
    when(() => mockDBManager.hotelsDao())
        .thenAnswer((_) async => mockHotelsDao);

    when(() => mockHotelListRepository.observerOfLoadingHotels)
        .thenReturn(hotelLoadingController);
    when(() => mockHotelsDao.observerOfInsertingHotels)
        .thenReturn(hotelInsertingController);
    when(() => mockCategoriesRepository.observerOfLoadingCategories)
        .thenReturn(categoriesLoadingController);
    when(() => mockAuthService.checkAutorization()).thenAnswer((_) async => {});

    splashCubit = SplashCubit();
  });

  tearDown(() {
    hotelLoadingController.close();
    hotelInsertingController.close();
    categoriesLoadingController.close();
    splashCubit.close();
  });

  group('SplashCubit Tests', () {
    test('Начальное состояние корректно', () {
      expect(splashCubit.state.message, 'Идет загрузка отелей...');
      expect(splashCubit.state.error, false);
      expect(splashCubit.state.progress, 0);
    });

    test('setProgress обновляет прогресс и сообщение', () {
      splashCubit.setProgress(50);
      expect(splashCubit.state.progress, 50);
      expect(splashCubit.state.message, 'Сохранено 50% отелей');
    });

    test('setError устанавливает ошибку и отменяет подписки', () {
      splashCubit.setError('Ошибка');
      expect(splashCubit.state.error, true);
      expect(splashCubit.state.message, 'Ошибка');
    });

    test('startLoading вызывает checkAutorization и слушает стримы', () async {
      splashCubit.startLoading();

      verify(() => mockAuthService.checkAutorization()).called(1);

      // Имитируем ошибку загрузки отелей
      hotelLoadingController.add(true);

      // Ждем обработки асинхронного события
      await Future.delayed(Duration.zero);
      expect(splashCubit.state.error, true);
      expect(splashCubit.state.message,
          'Ошибка при скачивании отелей. Попробуйте повторить позже.');
    });

    test('Обновление прогресса через стрим', () async {
      splashCubit.startLoading();

      // Ждем пока подписки инициализируются (hotelsDao асинхронный)
      await Future.delayed(Duration.zero);

      hotelInsertingController.add(75);

      await Future.delayed(Duration.zero);
      expect(splashCubit.state.progress, 75);
      expect(splashCubit.state.message, 'Сохранено 75% отелей');
    });
  });
}
