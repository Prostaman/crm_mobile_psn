import 'dart:io';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:psn.hotels.hub/blocks/base_cubit/base_cubit.dart';
import 'package:psn.hotels.hub/db/dao/categories_dao.dart';
import 'package:psn.hotels.hub/db/db_manager.dart';
import 'package:psn.hotels.hub/helpers/file_utility.dart';
import 'package:psn.hotels.hub/helpers/format_date.dart';
import 'package:psn.hotels.hub/models/entities_database/category_of_location_model.dart';
import 'package:psn.hotels.hub/models/entities_database/file_model.dart';
import 'package:psn.hotels.hub/models/entities_database/location_model.dart';
import 'package:psn.hotels.hub/models/entities_database/my_hotel_model.dart';
import 'package:psn.hotels.hub/models/response_models/file_model_response.dart';
import 'package:psn.hotels.hub/repository/locations_repository.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_compress/video_compress.dart';
import '../../repository/repository_container.dart';
import 'package:mime/mime.dart';
import 'package:path_provider/path_provider.dart';
import 'package:collection/collection.dart';

class MyHotelCubit extends BaseCubit {
  MyHotelModel myHotelModel;
  final DBManager db;

  late LocationModel locationModel;
  late bool editing;
  List<FileModel> selectedFiles = [];
  List<FileModel> files = [];
  List<CategoryModel> categories = [];
  CategoryModel category = CategoryModel(id: -1, description: 'Выберите категорию *');

  MyHotelCubit({LocationModel? location, required this.myHotelModel, required this.db}) : super(InitialState()) {
    editing = location != null;
    locationModel = location != null ? location : LocationModel();
  }

  Future<void> addAndUpdateLocationWithFiles(List<FileModel> files) async {
    Future<void> moveFilesToInternalStorage(FileModel file, Directory documentsDirectory) async {
      file.localPath = await FileUtility.moveFile(File(file.localPath), documentsDirectory.path); //перемещение файла во внутренее хранилище
      if (file.type == FileModelType.Video && ((file.thumb ?? '').isNotEmpty)) {
        //String tempOldThumb = file.thumb!;

        file.thumb = await FileUtility.moveFile(File(file.thumb!), documentsDirectory.path); //перемещение картинки of видео во внутренее хранилище

        // if (file.thumb != tempOldThumb) {
        //   //перезаписывает thumb для всех видео у который совпадает путь к thumb
        //   List<FileModel> theSameVideos = files.where((element) => element.type == FileModelType.Video && element.thumb == tempOldThumb).toList();
        //   debugPrint('theSameVideos:${theSameVideos.length}');
        //   theSameVideos.forEach((item) {
        //     if (item.thumb == tempOldThumb) {
        //       item.thumb = file.thumb;
        //     }
        //   });
        // }
      }
    }

    Future<void> moveProfilePhotosToInternalStorage(String oldLocalPath, FileModel file, HotelLocationsRepository repository) async {
      if (locationModel.pathOfProfilePhoto == oldLocalPath) {
        locationModel.pathOfProfilePhoto = file.localPath; //перезапись профильного фото, если оно было перемещено
        await repository.updateLocation(hotelModel: myHotelModel, locationModel: locationModel);
      }

      if (myHotelModel.pathOfProfilePhoto == oldLocalPath) {
        myHotelModel.pathOfProfilePhoto = file.localPath; //перезапись профильного фото, если оно было перемещено
        await RepositoryContainer().myHotelRepository.updateMyHotel(model: myHotelModel);
      }
    }

    debugPrint('addAndUpdateLocationWithFiles');
    emit(LoadingState());
    try {
      HotelLocationsRepository repository = RepositoryContainer().locationsRepository;
      Directory documentsDirectory = await getApplicationDocumentsDirectory();
      //debugPrint('documentsDirectory: ${documentsDirectory.path}');
      if (editing == true) {
        var lastUpdateOfLocation = await repository.getLocationFromLocalDB(locationModel.localId);
        String tempNameOfLocation = locationModel.name;
        String tempDescriptionOfLocation = locationModel.description;
        String tempPathOfProfilePhoto = locationModel.pathOfProfilePhoto;
        int tempCategoryId = locationModel.idCategory;
        if (lastUpdateOfLocation != null) {
          locationModel = lastUpdateOfLocation;
          locationModel.name = tempNameOfLocation;
          locationModel.description = tempDescriptionOfLocation;
          locationModel.pathOfProfilePhoto = tempPathOfProfilePhoto;
          locationModel.idCategory = tempCategoryId;
        }
        //debugPrint('locationModel updated: ${locationModel.pathOfProfilePhoto}');
        await repository.updateLocation(hotelModel: myHotelModel, locationModel: locationModel);
        for (var file in files) {
          debugPrint('mode: Edition, deleted:${file.deleted}, file.localPath: ${file.localPath}');
          if (!file.deleted && !file.localPath.contains(documentsDirectory.path)) {
            String oldLocalPath = file.localPath;
            await moveFilesToInternalStorage(file, documentsDirectory);
            if (oldLocalPath != file.localPath) {
              await moveProfilePhotosToInternalStorage(oldLocalPath, file, repository);
              file.isEdited = true;
              debugPrint('Was moving to internal storage:${file.localPath}');
            }
          }

          if (file.localLocationId == 0 && !file.deleted) {
            file.localLocationId = locationModel.localId;
            file.cloudLocationId = locationModel.cloudId;
            await repository.addFile(file: file);
          } else {
            if (file.isEdited) {
              //debugPrint('was changed file ${file.localId} with deleted=${file.deleted}');
              await repository.updateFile(file: file);
            }
          }
        }
      } else {
        locationModel.hotelId = myHotelModel.id;
        int localLocationId =
            await repository.addLocation(hotelModel: myHotelModel, locationModel: locationModel); // insert location to local db and get him id
        for (var file in files) {
          if (file.deleted == false) {
            debugPrint('deleted:${file.deleted}, file.localPath: ${file.localPath}');
            if (!file.localPath.contains(documentsDirectory.path)) {
              String oldLocalPath = file.localPath;
              await moveFilesToInternalStorage(file, documentsDirectory);
              if (oldLocalPath != file.localPath) {
                await moveProfilePhotosToInternalStorage(oldLocalPath, file, repository);
                file.isEdited = true;
                debugPrint('Was moving to internal storage:${file.localPath}');
              }
            }
            file.localLocationId = localLocationId;
            await repository.addFile(file: file);
          }
        }
      }
      for (var file in files) {
        if (file.isEdited) {
          FileUtility.deleteFile(file.oldLocalPath);
          file.isEdited = false;
        }
      }
    } catch (e) {
      catchError(e);
    }
    emit(SuccessModelState(model: myHotelModel));
  }

  Future<void> startSync() async {

    HotelLocationsRepository repository = RepositoryContainer().locationsRepository;
    repository.startSinc();
  }

  Future<void> deleteLocation({required LocationModel model}) async {
    try {
      await RepositoryContainer().locationsRepository.deleteLocation(hotelModel: myHotelModel, locationModel: model);
    } catch (e) {
      catchError(e);
    }
  }

  Future<void> deleteSelectedFiles() async {
    //await RepositoryContainer().locationsRepository.deleteSelectedFiles(locationModel: locationModel, file: file);
    debugPrint("selectedFiles length:${selectedFiles.length}");
    selectedFiles.forEach((file) {
      file.synced = false;
      file.deleted = true;
      file.isEdited = true;
    });
    selectedFiles.clear();
    emit(RefreshState());
    emit(SuccessModelState(model: myHotelModel)); // если один и тот же State, то ui не обновляется
    //files.remove(file);
  }

  Future<void> deleteFile(FileModel file) async {
    //await RepositoryContainer().locationsRepository.deleteSelectedFiles(locationModel: locationModel, file: file);
    file.synced = false;
    file.deleted = true;
    file.isEdited = true;
    emit(RefreshState());
    //files.remove(file);
  }

  Future<void> shareSelectedFiles() async {
    List<XFile> listForSharing = [];
    for (var selectedFile in selectedFiles) {
      listForSharing.add(XFile(selectedFile.localPath));
    }
    await Share.shareXFiles(listForSharing);
    selectedFiles.clear();
  }

  Future<List<FileModel>> findFilesByLocationId() async {
    var files = await (await db.filesDao()).findFilesByLocationId(locationModel.localId) ?? [];
    // Фильтруем список, чтобы оставить только не удаленные файлы
    files.where((file) => file.deleted == false).toList();
    // сортируем по дате создания
    files.sort((a, b) {
      DateTime dateA = stringToDate(a.createdAt ?? '2000-01-01T00:00:00')!;
      DateTime dateB = stringToDate(b.createdAt ?? '2000-01-01T00:00:00')!;
      return dateB.compareTo(dateA);
    });

    files.forEach((file) {
      debugPrint('FileDate: ${file.createdAt}');
    });

    return files;
  }

  selectFile(FileModel file) {
    if (fileSelected(file) == true) {
      selectedFiles.remove(file);
    } else {
      selectedFiles.add(file);
    }
  }

  fileSelected(FileModel file) {
    var existIndex = selectedFiles.indexOf(file);
    if (existIndex != -1) {
      return true;
    } else {
      return false;
    }
  }

  Future<void> addFilesFromGallery() async {
    String getNameOfFile(String path) {
      // Find the position of the last '/'
      int lastIndex = path.lastIndexOf('/');

      // Return the substring after the last '/'
      return lastIndex != -1 ? path.substring(lastIndex + 1) : path;
    }

    void deleteDuplicates(List<XFile> xfilesFromGallery) {
      List<XFile> xfilesRemoving = [];
      for (var xfile in xfilesFromGallery) {
        files.forEach((file) {
          debugPrint('xfile name:${getNameOfFile(xfile.path)} | file name:${getNameOfFile(file.localPath)} ');
        });

        debugPrint('is Duplicate?:${files.firstWhereOrNull((file) => (xfile.path == file.localPath)) != null}');
        bool isDuplicate = files.firstWhereOrNull((file) => (getNameOfFile(xfile.path) == getNameOfFile(file.localPath))) != null;
        if (isDuplicate == true) {
          debugPrint('было удаление');
          xfilesRemoving.add(xfile);
        }
      }

      if (xfilesRemoving.isNotEmpty) {
        emit(ErrorState(error: "Некоторые выбранные файлы уже загружены"));
      }
      xfilesRemoving.forEach((xfile) => xfilesFromGallery.remove(xfile));
    }

    emit(LoadingState());
    try {
      const double maxFileSizeInBytes = 100 * 1048576; //100 MB limit size for files
      List<FileModel> filesFromGallery = [];
      final ImagePicker _picker = ImagePicker();
      List<XFile> xfilesFromGallery = await _picker.pickMultipleMedia(imageQuality: 100);
      debugPrint('Удаляем дубликаты');

      deleteDuplicates(xfilesFromGallery);

      for (var xfile in xfilesFromGallery) {
        if (await xfile.length() <= maxFileSizeInBytes) {
          String? mimeStr = lookupMimeType(xfile.path);
          var fileType = mimeStr?.split('/');
          debugPrint('file type $fileType');
          if (fileType!.contains('image') || fileType.contains('video')) {
            FileModel file = FileModel();
            file.localPath = xfile.path;
            file.createdAt = (await FileUtility().getFileCreationDate(xfile.path))?.toIso8601String();
            file.size = await xfile.length() / 1024;
            // if (position != null) {
            //   file.lat = position.latitude;
            //   file.long = position.longitude;
            // }
            if (fileType.contains('video')) {
              file.name = "video_" + xfile.name;
              var thumb = await VideoCompress.getFileThumbnail(file.localPath);
              file.thumb = thumb.path;
            } else {
              file.name = "image_" + xfile.name;
            }

            filesFromGallery.add(file);
          } else {
            debugPrint("Файл не является медиафайлом");
            emit(ErrorState(error: "${xfile.name} не является медиафайлом"));
          }
        } else {
          debugPrint("Размер файла больше 100 МБ");
          emit(ErrorState(error: "Размер ${xfile.name} больше 100 МБ"));
        }
      }
      files = [...filesFromGallery, ...files];
    } catch (e) {
      String error = "Pick file, error:$e";
      debugPrint(error);
      await FirebaseCrashlytics.instance.log(error);
      await FirebaseCrashlytics.instance.recordFlutterError(FlutterErrorDetails(exception: error));
      emit(ErrorState(error: "Error: $e"));
    }
    emit(SuccessModelState(model: myHotelModel));
  }

  Future<void> setProfileImageOfLocation(FileModel file) async {
    locationModel.pathOfProfilePhoto = file.localPath;
    locationModel.profilePhotoIsChanged = true;
    //debugPrint("was setting ProfileImageOfLocation, ${myHotelModel.pathOfProfilePhoto}");
  }

  Future<void> setProfileImageOfMyHotel(FileModel file) async {
    myHotelModel.pathOfProfilePhoto = file.localPath;
    //debugPrint("was setting ProfileImageOfMyHotel, ${myHotelModel.pathOfProfilePhoto}");
    myHotelModel.profilePhotoIsChanged = true;
  }

  Future<void> saveProfileImageOfMyHotel() async {
    //debugPrint("was updating ProfileImageOfMyHotel, ${myHotelModel.pathOfProfilePhoto}");
    await (await db.myHotelsDao()).updateMyHotel(myHotelModel.id, myHotelModel);
  }

  Future<void> getAllCategories() async {
    CategoriesDao categoriesDao = await db.categoriesDao();
    categories = await categoriesDao.getAllCategories();
  }

  Future<CategoryModel> findCategoryById(int id) async {
    emit(LoadingState());
    //persons.firstWhere((person) => person.id == searchId, orElse: () => null);
    //CategoryModel category = await (await db.categoriesDao()).findCategoryById(id) ?? CategoryModel(id: -1, description: 'Выберите категорию *');
    CategoryModel category =
        categories.firstWhereOrNull((category) => category.id == id) ?? CategoryModel(id: -1, description: 'Выберите категорию *');
    emit(SuccessModelState(model: myHotelModel));
    return category;
  }
}
