import 'package:psn.hotels.hub/helpers/firebase/firebase_crashlytics_helper.dart';
import 'package:psn.hotels.hub/models/entities_database/category_of_location_model.dart';
import 'package:sqflite/sqflite.dart';

class CategoriesDao {
  final String tableName;
  final Database _database;

  CategoriesDao(this._database, this.tableName);

  Future<List<CategoryModel>> getAllCategories() async {
    try {
      List<Map<String, dynamic>> mapList = await _database.query(tableName);
      return mapList.map((map) => CategoryModel.fromMap(map)).toList();
    } catch (e) {
      FirebaseCrashlyticsHelper.recordDaoLocalDBError(e.toString(), "getAllCategories");
      throw e;
    }
  }


  Future<void> insertCategories(List<CategoryModel> categories) async {
    try {
      Batch batch = _database.batch();
      for (var category in categories) {
        batch.insert(tableName, category.toMap(), conflictAlgorithm: ConflictAlgorithm.ignore);
      }
      await batch.commit(noResult: true);
    } catch (e) {
      FirebaseCrashlyticsHelper.recordDaoLocalDBError(e.toString(), "insertCategories");
      throw e;
    }
  }

  Future<CategoryModel?> findCategoryById(int id) async {
    try {
      List<Map<String, dynamic>> categories = await _database.query(
        tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
      if (categories.isNotEmpty) {
        return CategoryModel.fromMap(categories.first);
      } else {
        return null;
      }
    } catch (e) {
      FirebaseCrashlyticsHelper.recordDaoLocalDBError(e.toString(), "findCategoryById");
      throw e;
    }
  }

    Future<bool> isTableCategoriesEmpty() async {
    int count = Sqflite.firstIntValue(await _database.rawQuery('SELECT COUNT(*) FROM $tableName')) ?? 0;
    return count == 0;
  }

  Future<void> clearCategoriesTable() async {
    try {
      await _database.delete(tableName);
    } catch (e) {
      FirebaseCrashlyticsHelper.recordDaoLocalDBError(e.toString(), "clearCategoriesTable");
      throw e;
    }
  }
}
