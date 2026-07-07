import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:psn.hotels.hub/data/datasources/local/db/dao/categories_dao.dart';
import 'package:psn.hotels.hub/data/datasources/local/db/db_manager.dart';
import 'package:psn.hotels.hub/data/datasources/remote/api/api_container.dart';
import 'package:psn.hotels.hub/data/datasources/remote/api/category_of_location_api.dart';
import 'package:psn.hotels.hub/data/repository/categories_repository.dart';
import 'package:psn.hotels.hub/data/models/response_models/categories_of_locations_response.dart';

class MockApiContainer extends Mock implements ApiContainer {}

class MockCategoryApi extends Mock implements CategoryApi {}

class MockDBManager extends Mock implements DBManager {}

class MockCategoriesDao extends Mock implements CategoriesDao {}

void main() {
  late CategoriesRepository repository;
  late MockApiContainer mockApiContainer;
  late MockCategoryApi mockCategoryApi;
  late MockDBManager mockDBManager;
  late MockCategoriesDao mockCategoriesDao;

  setUp(() {
    mockApiContainer = MockApiContainer();
    mockCategoryApi = MockCategoryApi();
    mockDBManager = MockDBManager();
    mockCategoriesDao = MockCategoriesDao();

    ApiContainer.instance = mockApiContainer;
    DBManager.instance = mockDBManager;

    when(() => mockApiContainer.categoryApi).thenReturn(mockCategoryApi);
    when(() => mockDBManager.categoriesDao())
        .thenAnswer((_) async => mockCategoriesDao);

    repository = CategoriesRepository();
  });

  group('CategoriesRepository Tests', () {
    test('downloadCategories возвращает true при успехе', () async {
      final response = CategoriesResponse(success: true, list: []);

      when(() => mockCategoryApi.getAll()).thenAnswer((_) async => response);

      final result = await repository.downloadCategories();

      expect(result, true);
      verify(() => mockCategoryApi.getAll()).called(1);
    });

    test('downloadCategories возвращает false после 4 попыток', () async {
      final response = CategoriesResponse(success: false, list: []);

      when(() => mockCategoryApi.getAll()).thenAnswer((_) async => response);

      final result = await repository.downloadCategories();

      expect(result, false);
      verify(() => mockCategoryApi.getAll()).called(4);
    }, timeout: Timeout(Duration(seconds: 15)));
  });
}
