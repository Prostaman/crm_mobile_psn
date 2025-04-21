import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:psn.hotels.hub/db/dao/files_dao.dart';
import 'package:psn.hotels.hub/db/dao/locations_dao.dart';
import 'package:psn.hotels.hub/db/dao/my_hotels_dao.dart';
import 'package:psn.hotels.hub/helpers/file_utility.dart';
import 'package:psn.hotels.hub/models/entities_database/file_model.dart';
import 'package:psn.hotels.hub/models/entities_database/location_model.dart';
import 'package:psn.hotels.hub/models/entities_database/my_hotel_model.dart';
import 'package:psn.hotels.hub/models/response_models/file_model_response.dart';
import 'package:psn.hotels.hub/services/service_container.dart';
import '../helpers/firebase/firebase_crashlytics_helper.dart';
import '../repository/repository_container.dart';

// Класс для синхронизации того, что добавили без интернета.
// При появлении интернета - синхронизируем отели/локации/фото
class SinkService {
  //singleton
  static final SinkService _instance = SinkService._internal();
  factory SinkService() => _instance;

  late StreamSubscription connectivity;
  StreamController syncSuccess = new StreamController<bool>.broadcast();
  StreamController isSyncingObserver = new StreamController<bool>.broadcast();
  bool isSyncing = false;
  bool wasTryToSyncingDuringSyncing = false;

  SinkService._internal() {
    initObserverInternetConnection();
  }

  Future<void> initObserverInternetConnection() async {
    connectivity = Connectivity().onConnectivityChanged.listen((ConnectivityResult result) async {
      String? token = ServiceContainer().authService.user?.token;
      if (token != null && token.isNotEmpty) {
        debugPrint("onConnectivityChanged");
        if (ServiceContainer().settingsService.uploadIfWiFiEnable == true) {
          debugPrint("uploadIfWiFiEnable == true");
          if (result == ConnectivityResult.wifi) {
            debugPrint("wifi is connected so startSinc");
            startSinc();
          }
        } else {
          if (result == ConnectivityResult.ethernet || result == ConnectivityResult.wifi || result == ConnectivityResult.mobile) {
            debugPrint("ConnectivityResult.ethernet is true so startSinc, isSyncing:$isSyncing");
            startSinc();
          }
        }
      }
    });
  }

  Future<void> deleteRussianAndBelorusianHotels() async {
    await RepositoryContainer().hotelListRepository.deleteRussianAndBelorusianHotels();
  }

  Future<void> startDownloadHotels() async {
    var typeOfConnectionWithInternet = await (Connectivity().checkConnectivity());
    if (typeOfConnectionWithInternet != ConnectivityResult.none) {
      if (ServiceContainer().settingsService.uploadIfWiFiEnable == true) {
        if (typeOfConnectionWithInternet != ConnectivityResult.wifi) {
          return;
        }
      }
      await RepositoryContainer().hotelListRepository.downloadAllHotels();
      debugPrint("startSinc after downloading hotel, isSyncing:$isSyncing ");
      await startSinc();
      //deletingLostFiles(RepositoryContainer().myHotelRepository.db);
    }
  }

  Future<void> startSinc() async {
    debugPrint("isSyncing:$isSyncing");
    wasTryToSyncingDuringSyncing = true;
    if (!isSyncing) {
      debugPrint("startSinc");
      wasTryToSyncingDuringSyncing = false;
      isSyncing = true;
      isSyncingObserver.add(isSyncing);
      bool wasChanging = false;

      var typeOfConnectionWithInternet = await (Connectivity().checkConnectivity());
      // String? token = ServiceContainer().authService.user?.token;
      // if (token != null && token.isNotEmpty && typeOfConnectionWithInternet != ConnectivityResult.none) {
      if (typeOfConnectionWithInternet != ConnectivityResult.none) {
        if (ServiceContainer().settingsService.uploadIfWiFiEnable == true) {
          if (typeOfConnectionWithInternet != ConnectivityResult.wifi) {
            isSyncing = false;
            isSyncingObserver.add(isSyncing);
            return;
          }
        }

        // синхронизация списка отелей
        //await RepositoryContainer().hotelListRepository.syncHotels();

        // синхронизация МОИХ отелей.
        // это те, где я был, снимал фото, но был без интернета
        // теперь эти данные нужно отправиить в БД псн

        var db = RepositoryContainer().myHotelRepository.db;
        MyHotelsDao myHotelsDao = await db.myHotelsDao();
        LocationsDao locationsDao = await db.locationsDao();
        FilesDao filesDao = await db.filesDao();

        try {
          var myHotels = await RepositoryContainer().myHotelRepository.allMyHotels;
          var myHotelsNotSynced = myHotels.where((element) => element.synced == false).toList();
          for (var myHotel in myHotelsNotSynced) {
            if (myHotel.deleted == true) {
              var response = await RepositoryContainer().myHotelRepository.hotelApi.deleteMyHotel(myHotelId: myHotel.id);
              if (response != null && response.success == true) {
                wasChanging = true;
                var locationsMap = await locationsDao.findLocationsByHotelId(myHotel.id) ?? [];
                var locations = locationsMap.map((map) => LocationModel.fromMap(map)).toList();
                for (var location in locations) {
                  var files = await filesDao.findFilesByLocationId(location.localId) ?? [];
                  for (var file in files) {
                    await filesDao.deleteFile(file.localId, file.localPath);
                  }
                }
                await (locationsDao).deleteLocationsByHotelId(myHotel.id);
                await myHotelsDao.deleteMyHotel(myHotel.id);
              } else {
                FirebaseCrashlyticsHelper.recordApiError(response, "deleteMyHotel");
              }
            } else {
              var response = await RepositoryContainer().myHotelRepository.hotelApi.updateMyHotel(myHotel);
              if (response != null && response.success == true) {
                wasChanging = true;
                myHotel.synced = true;
                await (myHotelsDao).updateMyHotel(myHotel.id, myHotel);
              } else {
                FirebaseCrashlyticsHelper.recordApiError(response, "updateMyHotel");
              }
            }
          }
        } catch (e) {
          isSyncing = false;
          isSyncingObserver.add(isSyncing);
          FirebaseCrashlytics.instance.log("Error update or delete MyHotel: $e");
          FirebaseCrashlytics.instance.recordFlutterError(FlutterErrorDetails(exception: e));
          throw e;
        }

        // try {
        var locationsAll = await RepositoryContainer().locationsRepository.allLocations;
        // var currentDate = DateTime.now();
        for (var location in locationsAll) {
          bool saveLocation = false;
          //List<FileModel> deletions = [];
          // Синхронизация списка локаций
          if (location.synced == false && location.deleted == true) {
            var response = await RepositoryContainer().locationsRepository.locationApi.deleteLocation(request: location);
            if (response != null && response.success == true) {
              wasChanging = true;
              debugPrint("Deleting location on the backend: success");
              var files = await filesDao.findFilesByLocationId(location.localId) ?? [];
              for (var file in files) {
                await filesDao.deleteFile(file.localId, file.localPath);
              }
              await locationsDao.deleteLocation(location.localId);
            } else {
              FirebaseCrashlyticsHelper.recordApiError(response, "deleteLocation");
            }
          } else if (location.synced == false && location.deleted == false) {
            debugPrint("addLocation, location.synced == false && location.deleted == false");
            //обновление
            var r = await RepositoryContainer().locationsRepository.locationApi.addLocation(location: location);
            if (r.success == true) {
              wasChanging = true;
              location.synced = true;
              var oldLocationCloudId = location.cloudId;
              location.cloudId = r.item?.cloudId ?? 0;
              await locationsDao.updateLocation(location.localId, location);
              debugPrint("oldLocationCloudId: $oldLocationCloudId");
              if (oldLocationCloudId == 0) {
                var files = await filesDao.findFilesByLocationId(location.localId) ?? [];
                for (var file in files) {
                  file.cloudLocationId = location.cloudId;
                  file.synced = false;
                  await filesDao.updateFile(file.localId, file);
                }
              }
            } else {
              FirebaseCrashlyticsHelper.recordApiError(r, "addLocation");
            }
          } else if (location.synced == true && location.deleted == true) {
            await locationsDao.deleteLocation(location.localId);
          }

          // синхронизация файлов
          var files = await filesDao.findFilesByLocationId(location.localId) ?? [];
          if (files.isNotEmpty) {
            for (var file in files) {
              if (file.synced == false && file.deleted == true) {
                debugPrint("Testing file.synced == false && file.deleted == true");
                var response;
                response = await RepositoryContainer().locationsRepository.filesApi.deleteFile(file: file);
                debugPrint("Testing got response delete file:$response");
                if (response != null && response.success == true) {
                  wasChanging = true;
                  debugPrint("Testing response success delete file");
                  //file.synced = true;
                  await filesDao.deleteFile(file.localId, file.localPath);
                  if (file.type == FileModelType.Video && (file.thumb ?? '').isNotEmpty) {
                    await FileUtility.deleteFile(file.thumb!);
                  }
                  saveLocation = true;
                } else {
                  FirebaseCrashlyticsHelper.recordApiError(response, "deleteFile");
                }
              } else if (file.synced == false && file.deleted == false) {
                //debugPrint("Testing file.synced == false && file.deleted == false  fileLocalId:${file.localId}");
                var r = await RepositoryContainer().locationsRepository.filesApi.send(file: file, hotelId: location.hotelId);
                debugPrint("sent file");
                if (r != null && r.success == true) {
                  wasChanging = true;
                  debugPrint("Testing reponse send file r != null && r.success == true");
                  file.cloudId = r.item?.id ?? 0;
                  // file.url = r.item.url;
                  debugPrint("item url: ${r.item?.url ?? "empty"}, item id: ${r.item?.id}");
                  file.synced = true;
                  file.uploadedAt = DateTime.now().toIso8601String();
                  await filesDao.updateFile(file.localId, file);
                  saveLocation = true;
                  //  } else if (r != null && r.errors.isNotEmpty) {
                } else {
                  file.syncError = true;
                  await filesDao.updateFile(file.localId, file);
                  FirebaseCrashlyticsHelper.recordApiError(r, "send File");
                }
              } else if (file.synced == true && file.deleted == true) {
                debugPrint("Testing file.synced == true && file.deleted == true");
                await filesDao.deleteFile(file.localId, file.localPath);
                saveLocation = true;
              }
            }
          }

          if (saveLocation == true) {
            await locationsDao.updateLocation(location.localId, location);
            wasChanging = true;
          }
        }
        await changingProfilePhoto(myHotelsDao, filesDao, locationsDao);
        if (wasChanging == true) {
          syncSuccess.add(true);
          debugPrint("setState after sinc");
        }
      }
      isSyncing = false;
      isSyncingObserver.add(isSyncing);
      if (wasTryToSyncingDuringSyncing == true) {
        debugPrint("(wasTryToSyncingDuringSyncing so startSinc");
        await startSinc();
      }
    }
  }

  Future<void> changingProfilePhoto(MyHotelsDao myHotelsDao, FilesDao filesDao, LocationsDao locationsDao) async {
    debugPrint("start changingProfilePhoto");
    try {
      List<MyHotelModel> myHotels = await myHotelsDao.findMyHotelsWithChangedProfilePhoto();
      for (var myHotel in myHotels) {
        debugPrint("myHotel.pathOfProfilePhoto:${myHotel.pathOfProfilePhoto}");
        FileModel file = await filesDao.findFileByLocalPath(myHotel.pathOfProfilePhoto);
        if (file.deleted == false && file.synced == true && file.cloudId != 0) {
          var response = await RepositoryContainer().locationsRepository.filesApi.changeProfilePhoto(cloudId: file.cloudId, isHotel: true);
          if (response != null && response.success == true) {
            myHotel.profilePhotoIsChanged = false;
            await myHotelsDao.updateMyHotel(myHotel.id, myHotel);
          } else {
            FirebaseCrashlyticsHelper.recordApiError(response, "changingProfilePhotoOfMyHotel");
          }
        }
      }
    } catch (e) {
      await FirebaseCrashlytics.instance.log("changingProfilePhoto in myHotel in sync");
      await FirebaseCrashlytics.instance.recordFlutterError(FlutterErrorDetails(exception: e));
    }
    try {
      List<LocationModel> locations = await locationsDao.findLocationsWithChangedProfilePhoto();
      for (var location in locations) {
        debugPrint("location.pathOfProfilePhoto:${location.pathOfProfilePhoto}");
        FileModel file = await filesDao.findFileByLocalPath(location.pathOfProfilePhoto);
        if (file.deleted == false && file.synced == true && file.cloudId != 0) {
          var response = await RepositoryContainer().locationsRepository.filesApi.changeProfilePhoto(cloudId: file.cloudId, isHotel: true);
          if (response != null && response.success == true) {
            location.profilePhotoIsChanged = false;
            await locationsDao.updateLocation(location.localId, location);
          } else {
            FirebaseCrashlyticsHelper.recordApiError(response, "changingProfilePhotoOfMyHotel");
          }
        }
      }
    } catch (e) {
      await FirebaseCrashlytics.instance.log("changingProfilePhoto of location in sync");
      await FirebaseCrashlytics.instance.recordFlutterError(FlutterErrorDetails(exception: e));
    }
  }

  // Future<void> deletingLostFiles(DB db) async {
  //   print("Start deleting lost files");
  //   List<FileModel> files = await db.getAllFiles();

  //   Future<void> deleteNotDetectedFiles(String path) async {
  //     var contents = Directory(path).listSync();
  //     print("content:${contents.length}");
  //     for (var content in contents) {
  //       bool isFileFound = files.firstWhereOrNull((file) => file.localPath == content.path) != null;
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

  //   if (files.isNotEmpty) {
  //     if (Platform.isAndroid) {
  //       var availablePath = files[0].localPath.substring(0, files[0].localPath.lastIndexOf('/'));
  //       deleteNotDetectedFiles(availablePath);
  //     } else if (Platform.isIOS) {
  //       int lastIndex = files[0].localPath.lastIndexOf('/');
  //       if (lastIndex != -1) {
  //         int secondLastIndex = files[0].localPath.lastIndexOf('/', lastIndex - 1);
  //         if (secondLastIndex != -1) {
  //           var cameraPath = files[0].localPath.substring(0, secondLastIndex);
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
            //     var files = await db.findFilesByLocationId(location.localId) ?? [];
            //     for (var file in files) {
            //       file.cloudLocationId = location.cloudId;
            //       await db.updateFile(file.localId, file);
            //     }
            //   } else {
            //     FirebaseCrashlyticsHelper.recordApiError(response, "addLocation with cloudId=0");
            //   }
            // }
            //конец отправки