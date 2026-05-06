import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:psn.hotels.hub/data/datasources/local/db/dao/categories_dao.dart';
import 'package:psn.hotels.hub/data/datasources/local/db/dao/files_dao.dart';
import 'package:psn.hotels.hub/data/datasources/local/db/db_manager.dart';
import 'package:psn.hotels.hub/data/models/entities_database/category_of_location_model.dart';
import 'package:psn.hotels.hub/data/models/entities_database/file_model.dart';
import 'package:psn.hotels.hub/data/models/entities_database/location_model.dart';
import 'package:psn.hotels.hub/data/models/entities_database/my_hotel_model.dart';
import 'package:psn.hotels.hub/presentation/blocks/content/content_cubit.dart';

class MockDBManager extends Mock implements DBManager {}

class MockFilesDao extends Mock implements FilesDao {}

class MockCategoriesDao extends Mock implements CategoriesDao {}

void main() {
  late ContentCubit contentCubit;
  late MockDBManager mockDBManager;
  late MockFilesDao mockFilesDao;
  late MockCategoriesDao mockCategoriesDao;
  late MyHotelModel testHotel;

  setUp(() {
    mockDBManager = MockDBManager();
    mockFilesDao = MockFilesDao();
    mockCategoriesDao = MockCategoriesDao();

    DBManager.instance = mockDBManager;

    when(() => mockDBManager.filesDao()).thenAnswer((_) async => mockFilesDao);
    when(() => mockDBManager.categoriesDao())
        .thenAnswer((_) async => mockCategoriesDao);

    testHotel = MyHotelModel()
      ..id = 1
      ..name = 'Test Hotel'
      ..createdAt = '2023-01-01'
      ..updatedAt = '2023-01-01'
      ..country = 'UA'
      ..resort = 'Odesa';
  });

  group('ContentCubit Tests', () {
    test('Начальное состояние корректно', () {
      contentCubit = ContentCubit(myHotel: testHotel);
      expect(contentCubit.state.myHotel.id, 1);
      expect(contentCubit.state.isLoading, false);
    });

    test('init загружает категории и файлы', () async {
      final categories = [CategoryModel(id: 1, description: 'Cat 1')];
      when(() => mockCategoriesDao.getAllCategories())
          .thenAnswer((_) async => categories);
      when(() => mockCategoriesDao.findCategoryById(any()))
          .thenAnswer((_) async => categories.first);
      when(() => mockFilesDao.findNotDeletedFilesByLocationId(any()))
          .thenAnswer((_) async => []);

      contentCubit = ContentCubit(
          myHotel: testHotel, location: LocationModel().copyWith(localId: 10));

      await contentCubit.init();

      expect(contentCubit.state.categories, categories);
      expect(contentCubit.state.isLoading, false);
      verify(() => mockCategoriesDao.getAllCategories()).called(1);
      verify(() => mockFilesDao.findNotDeletedFilesByLocationId(10)).called(1);
    });

    test('selectFile добавляет/удаляет id из выбранных', () {
      contentCubit = ContentCubit(myHotel: testHotel);
      final file = FileModel()
        ..localId = 5
        ..localPath = 'path';

      contentCubit.selectFile(file);
      expect(contentCubit.state.selectedIds.contains('5'), true);

      contentCubit.selectFile(file);
      expect(contentCubit.state.selectedIds.contains('5'), false);
    });

    test('setCategory обновляет категорию в стейте', () {
      contentCubit = ContentCubit(myHotel: testHotel);
      final cat = CategoryModel(id: 2, description: 'New Cat');

      contentCubit.setCategory(cat);

      expect(contentCubit.state.category, cat);
      expect(contentCubit.state.location.idCategory, 2);
    });
  });
}
