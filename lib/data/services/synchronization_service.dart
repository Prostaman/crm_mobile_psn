import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:psn.hotels.hub/data/datasources/local/db/dao/files_dao.dart';
import 'package:psn.hotels.hub/data/datasources/local/db/dao/locations_dao.dart';
import 'package:psn.hotels.hub/data/datasources/local/db/dao/my_hotels_dao.dart';
import 'package:psn.hotels.hub/infrastructure/file_utility.dart';
import 'package:psn.hotels.hub/data/models/entities_database/file_model.dart';
import 'package:psn.hotels.hub/data/models/entities_database/location_model.dart';
import 'package:psn.hotels.hub/data/models/entities_database/my_hotel_model.dart';
import 'package:psn.hotels.hub/data/models/response_models/file_model_response.dart';
import 'package:psn.hotels.hub/di/service_container.dart';

import '../../data/repository/repository_container.dart';
import '../../infrastructure/firebase/firebase_crashlytics_helper.dart';

// Класс для синхронизации того, что добавили без интернета.
// При появлении интернета - синхронизируем отели/локации/фото
class SinkService {
  //singleton
  static final SinkService _instance = SinkService._internal();

  factory SinkService() => _instance;

  StreamSubscription? connectivity;

  //StreamController syncSuccess = new StreamController<bool>.broadcast();
  StreamController syncMyHotelsObserver = new StreamController<int>.broadcast();
  StreamController syncLocationsObserver =
      new StreamController<int>.broadcast();
  StreamController syncFilesObserver = new StreamController<int>.broadcast();
  StreamController isSyncingObserver = new StreamController<bool>.broadcast();
  bool isSyncing = false;
  bool wasTryToSyncingDuringSyncing = false;

  SinkService._internal() {
    initObserverInternetConnection();
  }

  _notifyFileChanged(int local_file_id, int local_location_id, int hotel_id) {
    syncFilesObserver.add(local_file_id);
    syncLocationsObserver.add(local_location_id);
    syncMyHotelsObserver.add(hotel_id);
  }

  _notifyLocationChanged(int local_location_id, int hotel_id) {
    syncLocationsObserver.add(local_location_id);
    //syncMyHotelsObserver.add(hotel_id);
  }

  Future<void> initObserverInternetConnection() async {
    await connectivity?.cancel();

    connectivity = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) async {
      String? token = ServiceContainer().authService.user?.token;

      if (token != null && token.isNotEmpty) {
        debugPrint("onConnectivityChanged");

        final hasWifi = results.contains(ConnectivityResult.wifi);
        final hasMobile = results.contains(ConnectivityResult.mobile);
        final hasEthernet = results.contains(ConnectivityResult.ethernet);

        if (ServiceContainer().settingsService.uploadIfWiFiEnable == true) {
          debugPrint("uploadIfWiFiEnable == true");

          if (hasWifi) {
            debugPrint("wifi is connected so startSync");
            startSynchronization();
          }
        } else {
          if (hasWifi || hasMobile || hasEthernet) {
            debugPrint("Internet available so startSync, isSyncing:$isSyncing");
            startSynchronization();
          }
        }
      }
    });
  }

  Future<void> deleteRussianAndBelorusianHotels() async {
    await RepositoryContainer()
        .hotelListRepository
        .deleteRussianAndBelorusianHotels();
  }

  Future<void> startDownloadHotels() async {
    var connectivityResults = await (Connectivity().checkConnectivity());
    if (!connectivityResults.contains(ConnectivityResult.none)) {
      if (ServiceContainer().settingsService.uploadIfWiFiEnable == true) {
        if (!connectivityResults.contains(ConnectivityResult.wifi)) {
          return;
        }
      }
      await RepositoryContainer().hotelListRepository.downloadAllHotels();
      debugPrint("startSinc after downloading hotel, isSyncing:$isSyncing ");
      await startSynchronization();
      //deletingLostFiles(RepositoryContainer().myHotelRepository.db);
    }
  }

  Future<void> startSynchronization() async {
    debugPrint("isSyncing:$isSyncing");
    wasTryToSyncingDuringSyncing = true;
    if (!isSyncing) {
      debugPrint("startSynchronization");
      wasTryToSyncingDuringSyncing = false;
      isSyncing = true;
      isSyncingObserver.add(isSyncing);

      var connectivityResults = await (Connectivity().checkConnectivity());
      if (!connectivityResults.contains(ConnectivityResult.none)) {
        if (ServiceContainer().settingsService.uploadIfWiFiEnable == true) {
          if (!connectivityResults.contains(ConnectivityResult.wifi)) {
            isSyncing = false;
            isSyncingObserver.add(isSyncing);
            return;
          }
        }

        var db = RepositoryContainer().myHotelRepository.db;
        MyHotelsDao myHotelsDao = await db.myHotelsDao();
        LocationsDao locationsDao = await db.locationsDao();
        FilesDao filesDao = await db.filesDao();
        // синхронизация МОИХ отелей.
        // это те, где я был, снимал фото, но был без интернета
        // теперь эти данные нужно отправиить в БД псн

        // синхронизация my hotels
        _deleteMyHotelWithContent(int myHotelId) async {
          var locationsMap =
              await locationsDao.findLocationsByHotelId(myHotelId) ?? [];
          var locations =
              locationsMap.map((map) => LocationModel.fromMap(map)).toList();
          for (var location in locations) {
            var files =
                await filesDao.findFilesByLocationId(location.localId) ?? [];
            for (var file in files) {
              await filesDao.deleteFile(file.localId, file.localPath);
              //   syncFilesObserver.add(file.localId);
            }
          }
          await (locationsDao).deleteLocationsByHotelId(myHotelId);
          // for (var location in locations) {
          //   syncLocationsObserver.add(location.localId);
          // }
          await myHotelsDao.deleteMyHotel(myHotelId);
          //syncMyHotelsObserver.add(myHotelId);
        }

        try {
          var myHotels = await RepositoryContainer()
              .myHotelRepository
              .allMyHotelsToSynchronization;
          for (var myHotel in myHotels) {
            if (myHotel.synced == false && myHotel.deleted == true) {
              var response = await RepositoryContainer()
                  .myHotelRepository
                  .hotelApi
                  .deleteMyHotel(myHotelId: myHotel.id);
              if (response != null && response.success == true) {
                _deleteMyHotelWithContent(myHotel.id);
              } else {
                FirebaseCrashlyticsHelper.recordApiError(
                    response, "deleteMyHotel");
              }
            } else if (myHotel.synced == false && myHotel.deleted == false) {
              var response = await RepositoryContainer()
                  .myHotelRepository
                  .hotelApi
                  .updateMyHotel(myHotel);
              if (response != null && response.success == true) {
                myHotel.synced = true;
                await (myHotelsDao).updateMyHotel(myHotel.id, myHotel);
                syncMyHotelsObserver.add(myHotel.id);
              } else {
                FirebaseCrashlyticsHelper.recordApiError(
                    response, "updateMyHotel");
              }
            } else if (myHotel.synced == true && myHotel.deleted == true) {
              // теоретически такого кейса не должно быть
              _deleteMyHotelWithContent(myHotel.id);
            }
          }
        } catch (e) {
          await FirebaseCrashlytics.instance
              .log("error in my_hotels_synchronization");
          await FirebaseCrashlytics.instance
              .recordFlutterError(FlutterErrorDetails(exception: e));
        }

        //синхронизация локаций
        _deleteLocationWithContent(int locationLocalId) async {
          var files =
              await filesDao.findFilesByLocationId(locationLocalId) ?? [];
          for (var file in files) {
            await filesDao.deleteFile(file.localId, file.localPath);
          }
          await locationsDao.deleteLocation(locationLocalId);
        }

        try {
          var locationsAll = await RepositoryContainer()
              .locationsRepository
              .allLocationsForSynchronization;
          for (var location in locationsAll) {
            // Синхронизация списка локаций
            if (location.synced == false && location.deleted == true) {
              var response = await RepositoryContainer()
                  .locationsRepository
                  .locationApi
                  .deleteLocation(request: location);
              if (response != null && response.success == true) {
                debugPrint("Deleting location on the backend: success");
                _deleteLocationWithContent(location.localId);
              } else {
                FirebaseCrashlyticsHelper.recordApiError(
                    response, "deleteLocation");
              }
            } else if (location.synced == false && location.deleted == false) {
              debugPrint(
                  "addLocation, location.synced == false && location.deleted == false");
              //обновление
              var r = await RepositoryContainer()
                  .locationsRepository
                  .locationApi
                  .addLocation(location: location);
              if (r.success == true) {
                location.synced = true;
                var oldLocationCloudId = location.cloudId;
                location.cloudId = r.item?.cloudId ?? -1;
                await locationsDao.updateLocation(location);
                _notifyLocationChanged(location.localId, location.hotelId);
                debugPrint("oldLocationCloudId: $oldLocationCloudId");
                if (oldLocationCloudId <= 0) {
                  var files =
                      await filesDao.findFilesByLocationId(location.localId) ??
                          [];
                  for (var file in files) {
                    file.cloudLocationId = location.cloudId;
                    file.synced = false;
                    await filesDao.updateFile(file.localId, file);
                    _notifyFileChanged(
                        file.localId, location.localId, location.hotelId);
                  }
                }
              } else {
                FirebaseCrashlyticsHelper.recordApiError(r, "addLocation");
              }
            } else if (location.synced == true && location.deleted == true) {
              // такой кейс маловероятен
              _deleteLocationWithContent(location.localId);
            }
          }
        } catch (e) {
          await FirebaseCrashlytics.instance
              .log("error in location_synchronization");
          await FirebaseCrashlytics.instance
              .recordFlutterError(FlutterErrorDetails(exception: e));
        }

        // синхронизация файлов
        _deleteFile(FileModel file) async {
          await filesDao.deleteFile(file.localId, file.localPath);
          if (file.type == FileModelType.Video &&
              (file.thumb ?? '').isNotEmpty) {
            await FileUtility.deleteFile(file.thumb!);
          }
        }

        try {
          var files = await filesDao.getFilesToSync();
          for (var file in files) {
            if (file.synced == false && file.deleted == true) {
              debugPrint("file.synced == false && file.deleted == true");
              var response;
              response = await RepositoryContainer()
                  .locationsRepository
                  .filesApi
                  .deleteFile(file: file);
              debugPrint("Got response delete file:$response");
              if (response != null && response.success == true) {
                debugPrint("Response success delete file");
                _deleteFile(file);
                // saveLocation = true;
              } else {
                FirebaseCrashlyticsHelper.recordApiError(
                    response, "deleteFile");
              }
            } else if (file.synced == false && file.deleted == false) {
              var r = await RepositoryContainer()
                  .locationsRepository
                  .filesApi
                  .send(file: file, hotelId: file.hotelId!);

              debugPrint("sent file");
              if (r != null && r.success == true) {
                //wasChangingForUI = true;
                debugPrint(
                    "Testing reponse send file r != null && r.success == true");
                file.cloudId = r.item?.id ?? 0;
                // file.url = r.item.url;
                debugPrint(
                    "item url: ${r.item?.url ?? "empty"}, item id: ${r.item?.id}");
                file.synced = true;
                file.uploadedAt = DateTime.now().toIso8601String();
                await filesDao.updateFile(file.localId, file);
                _notifyFileChanged(
                    file.localId, file.localLocationId, file.hotelId!);
              } else {
                file.syncError = true;
                await filesDao.updateFile(file.localId, file);
                syncFilesObserver.add(file.localId);
                FirebaseCrashlyticsHelper.recordApiError(r, "send File");
              }
            } else if (file.synced == true && file.deleted == true) {
              debugPrint("file.synced == true && file.deleted == true");
              _deleteFile(file);
            }
          }
        } catch (e) {
          await FirebaseCrashlytics.instance
              .log("error in files_synchronization");
          await FirebaseCrashlytics.instance
              .recordFlutterError(FlutterErrorDetails(exception: e));
        }

        await _changingProfilePhoto(myHotelsDao, filesDao, locationsDao);
        // if (wasChangingForUI == true) {
        //   syncSuccess.add(true);
        //   debugPrint("refresh after sinc");
        // }
      }
      isSyncing = false;
      isSyncingObserver.add(isSyncing);
      if (wasTryToSyncingDuringSyncing == true) {
        debugPrint("(TriedToSyncingDuringSyncing so start synchronization");
        await startSynchronization();
      }
    }
  }

  Future<void> _changingProfilePhoto(MyHotelsDao myHotelsDao, FilesDao filesDao,
      LocationsDao locationsDao) async {
    debugPrint("start changingProfilePhoto");
    try {
      List<MyHotelModel> myHotels =
          await myHotelsDao.findMyHotelsWithChangedProfilePhoto();
      for (var myHotel in myHotels) {
        debugPrint(
            "synchronization myHotel.pathOfProfilePhoto:${myHotel.pathOfProfilePhoto}");
        FileModel? file =
            await filesDao.findFileByLocalPath(myHotel.pathOfProfilePhoto);
        if (file != null &&
            file.deleted == false &&
            file.synced == true &&
            file.cloudId <= 0) {
          var response = await RepositoryContainer()
              .locationsRepository
              .filesApi
              .changeProfilePhoto(cloudId: file.cloudId, isHotel: true);
          if (response != null && response.success == true) {
            myHotel.profilePhotoIsChanged = false;
            await myHotelsDao.updateMyHotel(myHotel.id, myHotel);
            syncMyHotelsObserver.add(myHotel.id);
          } else {
            FirebaseCrashlyticsHelper.recordApiError(
                response, "changingProfilePhotoOfMyHotel");
          }
        }
      }
    } catch (e) {
      await FirebaseCrashlytics.instance
          .log("changingProfilePhoto in myHotel in sync");
      await FirebaseCrashlytics.instance
          .recordFlutterError(FlutterErrorDetails(exception: e));
    }
    try {
      List<LocationModel> locations =
          await locationsDao.findLocationsWithChangedProfilePhoto();
      for (var location in locations) {
        debugPrint(
            "location.pathOfProfilePhoto:${location.pathOfProfilePhoto}");
        FileModel? file =
            await filesDao.findFileByLocalPath(location.pathOfProfilePhoto);
        if (file != null &&
            file.deleted == false &&
            file.synced == true &&
            file.cloudId != -1 &&
            file.cloudId != 0) {
          var response = await RepositoryContainer()
              .locationsRepository
              .filesApi
              .changeProfilePhoto(cloudId: file.cloudId, isHotel: true);
          if (response != null && response.success == true) {
            location.profilePhotoIsChanged = false;
            await locationsDao.updateLocation(location);
            syncLocationsObserver.add(location.localId);
          } else {
            FirebaseCrashlyticsHelper.recordApiError(
                response, "changingProfilePhotoOfMyHotel");
          }
        }
      }
    } catch (e) {
      await FirebaseCrashlytics.instance
          .log("changingProfilePhoto of location in sync");
      await FirebaseCrashlytics.instance
          .recordFlutterError(FlutterErrorDetails(exception: e));
    }
  }

// Future<void> deletingLostFiles(DB db) async {
//   print("Start deleting lost content");
//   List<FileModel> content = await db.getAllFiles();

//   Future<void> deleteNotDetectedFiles(String path) async {
//     var contents = Directory(path).listSync();
//     print("content:${contents.length}");
//     for (var content in contents) {
//       bool isFileFound = content.firstWhereOrNull((file) => file.localPath == content.path) != null;
//       if (isFileFound == false) {
//         print("was deleting lost file");
//         await FirebaseAnalytics.instance.logEvent(
//           name: "deleting_file",
//           parameters: {
//             "content_type": "file",
//             "item_id": "was deleting lost file",
//           },
//         );
//         FileUtility.deleteFile(content.path);
//       }
//     }
//   }

//   if (content.isNotEmpty) {
//     if (Platform.isAndroid) {
//       var availablePath = content[0].localPath.substring(0, content[0].localPath.lastIndexOf('/'));
//       deleteNotDetectedFiles(availablePath);
//     } else if (Platform.isIOS) {
//       int lastIndex = content[0].localPath.lastIndexOf('/');
//       if (lastIndex != -1) {
//         int secondLastIndex = content[0].localPath.lastIndexOf('/', lastIndex - 1);
//         if (secondLastIndex != -1) {
//           var cameraPath = content[0].localPath.substring(0, secondLastIndex);
//           deleteNotDetectedFiles(cameraPath);
//         } else {
//           print("В строке нет предпоследнего символа '/'");
//         }
//       } else {
//         print("В строке нет символа '/'");
//       }
//     }
//   }
// }
}

//это удаление файлов через 24 часа, если стоит галочка "Удалить контент после загрузки"
// else if (file.synced == true && file.deleted == false) {
//   print("Testing file.synced == true && file.deleted == false");
//   if (ServiceContainer()
//           .settingsService
//           .deleteContentIfUploaded ==
//       true) {
//     var uploadedDate = stringToDate(file.uploadedAt);
//     var hours = uploadedDate == null
//         ? 0
//         : hoursBetween(uploadedDate, currentDate);
//     print("hour for success uploaded $hours");
//     if (hours >= 24) {
//     //удаление после 24 часов
//       db.deleteFile(file.localId, file.localPath);
//       saveLocation = true;
//     }
//   }
// }

// } catch (e) {
//   print(e);
//   await FirebaseCrashlytics.instance.log("sinc error:$e");
//   await FirebaseCrashlytics.instance.recordFlutterError(FlutterErrorDetails(exception: e));
//   isSyncing = false;
//   //throw e;
// }
//синхронизация моих отелей? ( то есть скачивание моих отелей с бекенда)?
// try {
//   var locations =
//       await RepositoryContainer().locationsRepository.getLocations();
//   locations.forEach((sLocation) async {
//     var myHotel = myHotels
//         .firstWhereOrNull((element) => element.id == sLocation.hotelId);
//     if (myHotel == null) {
//       var hotel = await RepositoryContainer()
//           .hotelListRepository
//           .findHotelFromLocalDBByIdRepository(sLocation.hotelId);
//       if (hotel != null) {
//         myHotel = await RepositoryContainer()
//             .myHotelRepository
//             .addMyHotel(hotel: hotel);
//       }
//     }

//     if (myHotel != null) {
//       var location = locationsDB
//           .firstWhereOrNull((element) => element.id == sLocation.id);
//       if (location == null) {
//         sLocation.createdAt = DateTime.now().toIso8601String();
//         sLocation.synced = true;
//         db.insertLocation(sLocation);
//       }
//     }
//   });

// окончание синхронизация моих отелей

// } catch (e) {
//   print(e);
//   throw e;
// }

//отправка локаций и файлов которые имеют cloudId=0
// var locations = await db.findLocationsByCloudId(0);
// for (var location in locations) {
//   var response = await RepositoryContainer().locationsRepository.locationApi.addLocation(location: location);
//   print("addLocation, because cloudId=0");
//   if (response.item != null && response.success == true && response.item?.cloudId != null) {
//     location.cloudId = response.item!.cloudId;
//     location.synced = true;
//     location.deleted = false;
//     await db.updateLocation(location.localId, location);
//     print("updatedLocation, cloudId: ${location.cloudId}");
//     var content = await db.findFilesByLocationId(location.localId) ?? [];
//     for (var file in content) {
//       file.cloudLocationId = location.cloudId;
//       await db.updateFile(file.localId, file);
//     }
//   } else {
//     FirebaseCrashlyticsHelper.recordApiError(response, "addLocation with cloudId=0");
//   }
// }
//конец отправки
