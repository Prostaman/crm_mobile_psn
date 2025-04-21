import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:psn.hotels.hub/db/dao/files_dao.dart';
import 'package:psn.hotels.hub/db/dao/hotels_dao.dart';
import 'package:psn.hotels.hub/db/dao/locations_dao.dart';
import 'package:psn.hotels.hub/db/dao/my_hotels_dao.dart';
import 'package:psn.hotels.hub/helpers/firebase/firebase_crashlytics_helper.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

import 'dao/categories_dao.dart';

class DBManager {
  static final DBManager _instance = DBManager._internal(); // signleton
  factory DBManager() => _instance; // signleton
  DBManager._internal(); // signleton

  Database? _database;

  Future<Database> get database async {
    // signleton
    if (_database != null) {
      return _database!;
    } else {
      _database = await initDB();
      return _database!;
    }
  }

  static const String nameOfTableHotels = "hotels_table";
  static const String nameOfTableMyHotels = "my_hotels_table";
  static const String nameOfTableLocations = "locations_table";
  static const String nameOfTableCategories = "categories_table";
  static const String nameOfTableFiles = "files_table";

  Future<Database> initDB() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'poehalisnami.db');
    debugPrint("path db: ${documentsDirectory.path}");
    Database database = await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion == 1) {
          await db.execute('''
      ALTER TABLE $nameOfTableMyHotels 
      ADD COLUMN profilePhotoIsChanged INTEGER DEFAULT 0
    ''');
          await db.execute('''
      ALTER TABLE $nameOfTableLocations 
      ADD COLUMN profilePhotoIsChanged INTEGER DEFAULT 0
    ''');
          oldVersion = 2;
        }

        if (oldVersion == 2) {
          await createCategoriesTable(db);

          await db.execute('''
            ALTER TABLE $nameOfTableLocations
            ADD COLUMN idCategory INTEGER DEFAULT 9
          ''');

          oldVersion = 3;
        }
      },
    );

    return database;
  }

  Future<void> createCategoriesTable(Database db) async {
    await db.execute('''
     CREATE TABLE IF NOT EXISTS $nameOfTableCategories (
        id INTEGER PRIMARY KEY,
        description TEXT
        )
  ''');
  }

  Future<void> _onCreate(Database db, int version) async {
    try {
      await db.execute('''
       CREATE TABLE IF NOT EXISTS $nameOfTableHotels (
        id INTEGER PRIMARY KEY,
        name TEXT,
        lat REAL,
        long REAL,
        active INTEGER,
        cid TEXT,
        country TEXT,
        resort TEXT
      )
    ''');

      await db.execute('''
       CREATE TABLE IF NOT EXISTS $nameOfTableMyHotels (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        description TEXT,
        createdAt TEXT,
        updatedAt TEXT,
        synced INTEGER, 
        deleted INTEGER,
        name TEXT,
        pathOfProfilePhoto TEXT,
        profilePhotoIsChanged INTEGER
        )
    ''');

      await db.execute('''
     CREATE TABLE IF NOT EXISTS $nameOfTableLocations (
        localId INTEGER PRIMARY KEY AUTOINCREMENT,
        cloudId INTEGER,
        hotelId INTEGER,
        name TEXT,
        description TEXT,
        createdAt TEXT,
        synced INTEGER,
        deleted INTEGER,
        pathOfProfilePhoto TEXT,
        profilePhotoIsChanged INTEGER,
        idCategory INTEGER
        )
  ''');

      await createCategoriesTable(db);

      await db.execute('''
    CREATE TABLE IF NOT EXISTS $nameOfTableFiles (
    localId INTEGER PRIMARY KEY AUTOINCREMENT,
    cloudId INTEGER,
    localLocationId INTEGER,
    cloudLocationId INTEGER,
    name TEXT,
    format TEXT,
    localPath TEXT,
    size REAL,
    synced INTEGER,
    syncError INTEGER,
    thumb TEXT,
    deleted INTEGER,
    lat REAL,
    long REAL,
    uploadedAt TEXT,
    createdAt TEXT,
    FOREIGN KEY (localLocationId) REFERENCES Location(id)
    )
  ''');
    } catch (e) {
      FirebaseCrashlyticsHelper.recordDaoLocalDBError(e.toString(), "Creating tables");
      throw e;
    }
  }

  Future<HotelsDao> hotelsDao() async {
    return HotelsDao(await database, nameOfTableHotels);
  }

  Future<MyHotelsDao> myHotelsDao() async {
    return MyHotelsDao(await database, nameOfTableMyHotels);
  }

  Future<LocationsDao> locationsDao() async {
    return LocationsDao(await database, nameOfTableLocations);
  }

  Future<CategoriesDao> categoriesDao() async {
    return CategoriesDao(await database, nameOfTableCategories);
  }

  Future<FilesDao> filesDao() async {
    return FilesDao(await database, nameOfTableFiles);
  }
}
