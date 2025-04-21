import 'dart:io';

import 'package:flutter/material.dart';
import 'package:psn.hotels.hub/helpers/file_utility.dart';
import 'package:psn.hotels.hub/helpers/firebase/firebase_crashlytics_helper.dart';
import 'package:psn.hotels.hub/models/entities_database/file_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class FilesDao {
  final String tableName;
  final Database _database;

  FilesDao(this._database, this.tableName);
    //обновляет UUID в path каждого файла, если он был изменён дабы не потерять файлы
  Future<void> updateUUID_of_Files() async {
      getUUID(String path) {
        RegExp regExp = RegExp(r'Application\/(.*?)\/Documents');
        RegExpMatch? match = regExp.firstMatch(path);
        String uuid = match!.group(1)!;
        return uuid;
      }

      Directory documentsDirectory = await getApplicationDocumentsDirectory();
      String current_UUID_of_db = getUUID(documentsDirectory.path);
      debugPrint('current_UUID_of_db: $current_UUID_of_db');

      List<FileModel> allFiles = await getAllFiles();
      for (FileModel file in allFiles) {
        String current_UUID_of_file = getUUID(file.localPath);
        debugPrint('current_UUID_of_file: $current_UUID_of_file');
        if (current_UUID_of_db != current_UUID_of_file) {
          file.localPath = file.localPath.replaceFirst(current_UUID_of_file, current_UUID_of_db);
          debugPrint('New file.localPath: ${file.localPath}');
          await updateFile(file.localId, file);
        }
      }
    
  }

  Future<List<FileModel>> getAllFiles() async {
    //Database db = await database;
    try {
      List<Map<String, dynamic>> mapList = await _database.query(tableName);
      return mapList.map((map) => FileModel.fromMap(map)).toList();
    } catch (e) {
      FirebaseCrashlyticsHelper.recordDaoLocalDBError(e.toString(), "getAllFiles");
      throw e;
    }
  }

  Future<List<FileModel>?> findFileBylocalId(int localId) async {
    //Database db = await database;
    try {
      List<Map<String, dynamic>> mapList = await _database.query(tableName, where: 'localId = ?', whereArgs: [localId], limit: 1);
      return mapList.map((map) => FileModel.fromMap(map)).toList();
    } catch (e) {
      FirebaseCrashlyticsHelper.recordDaoLocalDBError(e.toString(), "findFileBylocalId");
      throw e;
    }
  }

  Future<void> updateFile(int localId, FileModel newFile) async {
    //Database db = await database;
    try {
      await _database.update(
        tableName,
        newFile.toMap(),
        where: 'localId = ?',
        whereArgs: [localId],
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      FirebaseCrashlyticsHelper.recordDaoLocalDBError(e.toString(), "updateFile");
      throw e;
    }
  }

  Future<List<FileModel>?> findFilesByLocationId(int localLocationId) async {
    //Database db = await database;
    try {
      List<Map<String, dynamic>> mapList = await _database.query(
        tableName,
        where: 'localLocationId = ?',
        whereArgs: [localLocationId],
      );
      return mapList.map((map) => FileModel.fromMap(map)).toList();
    } catch (e) {
      FirebaseCrashlyticsHelper.recordDaoLocalDBError(e.toString(), "findFilesByLocationId");
      throw e;
    }
  }

  // Future<bool> isExistsFileByLocalPath(String localPath) async {
  //   try {
  //     List<Map<String, dynamic>> mapList = await _database.query(tableName, where: 'localPath = ?', whereArgs: [localPath], limit: 1);
  //     if (mapList.isNotEmpty) {
  //       return true; // true if file exists
  //     } else
  //       return false; // false if file not exists
  //   } catch (e) {
  //     FirebaseCrashlyticsHelper.recordDaoLocalDBError(e.toString(), "findFileByLocalPath");
  //     throw e;
  //   }
  // }

  Future<FileModel> findFileByLocalPath(String localPath) async {
    try {
      List<Map<String, dynamic>> mapList = await _database.query(tableName, where: 'localPath = ?', whereArgs: [localPath], limit: 1);
      return FileModel.fromMap(mapList.first);
    } catch (e) {
      FirebaseCrashlyticsHelper.recordDaoLocalDBError(e.toString(), "findFileByLocalPath");
      throw e;
    }
  }

  Future<void> insertFile(FileModel file) async {
    //Database db = await database;
    try {
      await _database.insert(tableName, file.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      FirebaseCrashlyticsHelper.recordDaoLocalDBError(e.toString(), "insertFile");
      throw e;
    }
  }

  Future<void> deleteFile(int localId, String filePath) async {
    try {
      FileUtility.deleteFile(filePath);
      await _database.delete(
        tableName,
        where: 'localId = ?',
        whereArgs: [localId],
      );
    } catch (e) {
      FirebaseCrashlyticsHelper.recordDaoLocalDBError(e.toString(), "deleteFile");
    }
  }

  Future<void> clearFilesTable() async {
    //Database db = await database;
    try {
      await _database.delete(tableName);
    } catch (e) {
      FirebaseCrashlyticsHelper.recordDaoLocalDBError(e.toString(), "clearFilesTable");
      throw e;
    }
  }
}
