import 'dart:async';
import 'dart:io';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
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
//import 'package:collection/collection.dart';
import 'states/files_screen_state.dart';

class FilesCubit extends Cubit<FilesState> {
  FilesCubit({
    required MyHotelModel myHotel,
    LocationModel? location,
  }) : super(FilesState(
            files: [],
            selectedIds: {},
            myHotel: myHotel,
            location: location ?? LocationModel(),
            category:
                CategoryModel(id: -1, description: 'Выберите категорию *'),
            categories: []));

  late final DBManager db;

  Future<void> init() async {
    Future<List<FileModel>> _getFiles() async {
      try {
        List<FileModel> files = await (await db.filesDao())
                .findNotDeletedFilesByLocationId(state.location.localId) ??
            [];
        files.sort((a, b) {
          DateTime dateA = stringToDate(a.createdAt ?? '2000-01-01T00:00:00')!;
          DateTime dateB = stringToDate(b.createdAt ?? '2000-01-01T00:00:00')!;
          return dateB.compareTo(dateA);
        });
        return files;
      } catch (e) {
        _catchError(e);
        return [];
      }
    }

    Future<List<CategoryModel>> _getAllCategories() async {
      return await (await db.categoriesDao()).getAllCategories();
    }

    Future<CategoryModel> _findCategoryById(int id) async {
      CategoryModel? categoryModel =
          await (await db.categoriesDao()).findCategoryById(id);
      return categoryModel ??
          CategoryModel(id: -1, description: 'Выберите категорию *');
    }

    _showLoading();
    try {
      List<CategoryModel> categories = await _getAllCategories();
      if (state.location.localId != -1) {
        List<FileModel> files = await _getFiles();
        CategoryModel currentCategory =
            await _findCategoryById(state.location.idCategory);
        emit(state.copyWith(
            isLoading: false,
            error: null,
            files: files,
            categories: categories,
            category: currentCategory));
      } else {
        emit(state.copyWith(
            isLoading: false, error: null, categories: categories));
      }
    } catch (e) {
      _catchError(e);
    }
  }

  _showLoading() {
    emit(state.copyWith(
      isLoading: true,
      error: null,
    ));
  }

  void _catchError(Object error, [StackTrace? stackTrace]) {
    debugPrint("Error: $error");
    emit(state.copyWith(
      isLoading: false,
      error: error.toString(),
    ));
    FirebaseCrashlytics.instance.recordError(error, stackTrace);
  }

  Future<void> save({
    required String currentName,
    required String currentDescription,
  }) async {
    Future<void> _saveProfileImageOfMyHotel() async {
      await (await db.myHotelsDao())
          .updateMyHotel(state.myHotel.id, state.myHotel);
    }

    Future<void> _addLocationWithContent() async {
      /// Вспомогательный метод для обновления путей профильных фото
      Future<void> _updateProfilePathsIfMatched(
          String oldPath, String newPath, LocationsRepository repo) async {
        if (state.location.pathOfProfilePhoto == oldPath) {
          state.location.pathOfProfilePhoto = newPath;
          await repo.updateLocation(locationModel: state.location);
        }

        if (state.myHotel.pathOfProfilePhoto == oldPath) {
          state.myHotel.pathOfProfilePhoto = newPath;
          await RepositoryContainer()
              .myHotelRepository
              .updateMyHotel(model: state.myHotel);
        }
      }

      debugPrint('FilesCubit: Saving location with content...');
      _showLoading();
      try {
        final repository = RepositoryContainer().locationsRepository;
        final documentsDir = await getApplicationDocumentsDirectory();

        // 1. Определяем, создаем или обновляем локацию
        bool isNewLocation = state.location.localId == -1;
        if (isNewLocation) {
          state.location.hotelId = state.myHotel.id;
          // Добавляем в БД и получаем новый localId
          state.location.localId = await repository.addLocation(
              hotelId: state.myHotel.id, locationModel: state.location);
        } else {
          // Обновляем существующую
          await repository.updateLocation(locationModel: state.location);
        }

        // 2. Обрабатываем файлы (один цикл на все случаи)
        for (var file in state.files) {
          if (file.deleted) continue;

          // А. Перемещение во внутреннее хранилище, если файл еще снаружи
          if (!file.localPath.contains(documentsDir.path)) {
            String oldPath = file.localPath;

            // Перемещаем основной файл
            file.localPath =
                await FileUtility.moveFile(File(oldPath), documentsDir.path);

            // Перемещаем превью видео, если есть
            if (file.type == FileModelType.Video &&
                (file.thumb?.isNotEmpty ?? false)) {
              file.thumb = await FileUtility.moveFile(
                  File(file.thumb!), documentsDir.path);
            }

            // Если этот файл был профильным — обновляем пути в моделях
            await _updateProfilePathsIfMatched(
                oldPath, file.localPath, repository);
            file.isEdited = true;
          }

          // Б. Привязка к локации и сохранение в БД
          if (file.localLocationId == -1) {
            file.localLocationId = state.location.localId;
            file.cloudLocationId = state.location.cloudId;
            await repository.addFile(file: file);
          } else if (file.isEdited) {
            await repository.updateFile(file: file);
          }
        }

        // 3. Удаление физических файлов, которые больше не нужны
        for (var file in state.files) {
          if (file.isEdited && file.oldLocalPath.isNotEmpty) {
            FileUtility.deleteFile(file.oldLocalPath);
            file.isEdited = false;
          }
        }
      } catch (e) {
        _catchError(e);
      }
    }

    state.location.name = currentName;
    state.location.description = currentDescription;
    await _addLocationWithContent();
    await _saveProfileImageOfMyHotel();
    startSync();
  }

  Future<void> startSync() async {
    LocationsRepository repository = RepositoryContainer().locationsRepository;
    repository.startSinc();
  }

  Future<void> deleteSelectedFiles() async {
    _showLoading();

    final selected = state.selectedIds;

    final updatedFiles = state.files.map((file) {
      if (!selected.contains(file.localId)) return file;

      return file.copyWith(
        synced: false,
        deleted: true,
      );
    }).toList();

    emit(state.copyWith(
      isLoading: false,
      files: updatedFiles,
      selectedIds: {},
    ));
  }

  Future<void> deleteFile(FileModel target) async {
    final updatedFiles = state.files.map((file) {
      if (file.localId != target.localId) return file;

      return file.copyWith(
        synced: false,
        deleted: true,
        //isEdited:true
      );
    }).toList();

    emit(state.copyWith(files: updatedFiles));
  }

  Future<void> shareSelectedFiles() async {
    final selected = state.selectedIds;
    final filesToShare = state.files
        .where((file) => selected.contains(file.localId))
        .map((file) => XFile(file.localPath))
        .toList();
    await SharePlus.instance.share(
      ShareParams(files: filesToShare),
    );
    emit(state.copyWith(selectedIds: {}));
  }

  void selectFile(FileModel file) {
    final updated = Set<int>.from(state.selectedIds);

    if (updated.contains(file.localId)) {
      updated.remove(file.localId);
    } else {
      updated.add(file.localId);
    }

    emit(state.copyWith(selectedIds: updated));
  }

  bool fileSelected(int localId) {
    return state.selectedIds.contains(localId);
  }

  Future<void> addFilesFromGallery() async {
    String _getNameOfFile(String path) {
      int lastIndex = path.lastIndexOf('/');
      return lastIndex != -1 ? path.substring(lastIndex + 1) : path;
    }

    void _deleteDuplicates(List<XFile> xfilesFromGallery) {
      debugPrint('Удаляем дубликаты');
      final existingNames =
          state.files.map((file) => _getNameOfFile(file.localPath)).toSet();
      bool hasDuplicates = false;
      xfilesFromGallery.removeWhere((xfile) {
        final isDuplicate = existingNames.contains(_getNameOfFile(xfile.path));
        if (isDuplicate) hasDuplicates = true;
        return isDuplicate;
      });
      if (hasDuplicates) {
        _catchError("Некоторые выбранные файлы уже загружены");
      }
    }

    _showLoading();
    // TODO: optimize with limited parallelism if performance issues appear
    try {
      const double maxFileSizeInBytes =
          100 * 1048576; //100 MB limit size for files
      List<FileModel> filesFromGallery = [];
      final ImagePicker _picker = ImagePicker();
      List<XFile> xfilesFromGallery =
          await _picker.pickMultipleMedia(imageQuality: 100);

      _deleteDuplicates(xfilesFromGallery);

      for (var xfile in xfilesFromGallery) {
        int xfileLength = await xfile.length();
        if (xfileLength <= maxFileSizeInBytes) {
          final mimeStr = lookupMimeType(xfile.path);
          if (mimeStr == null) {
            _catchError("${xfile.name} неизвестный тип файла");
            continue;
          }
          var fileType = mimeStr.split('/');
          debugPrint('file type $fileType');
          if (fileType.contains('image') || fileType.contains('video')) {
            final file = FileModel()
              ..localPath = xfile.path
              ..createdAt =
                  (await FileUtility().getFileCreationDate(xfile.path))
                      ?.toIso8601String()
              ..size = xfileLength / 1024
              ..name = "${fileType}_${xfile.name}";
            if (fileType == 'video') {
              final thumb =
                  await VideoCompress.getFileThumbnail(file.localPath);
              file.thumb = thumb.path;
            }
            filesFromGallery.add(file);
          } else {
            _catchError("${xfile.name} не является медиафайлом");
          }
        } else {
          _catchError("Размер ${xfile.name} больше 100 МБ");
        }
      }
      emit(state.copyWith(
          isLoading: false,
          error: null,
          files: [...filesFromGallery, ...state.files]));
    } catch (e) {
      final error = "Pick file, error:$e";
      _catchError(error);
    }
  }

  void setFilesFromCamera(List<FileModel> filesFromCamera) {
    emit(state.copyWith(
        isLoading: false,
        error: null,
        files: [...filesFromCamera.reversed, ...state.files]));
  }

  void setProfileImageOfLocation(FileModel file) {
    emit(state.copyWith(
        isLoading: false,
        error: null,
        location: state.location.copyWith(
            pathOfProfilePhoto: file.localPath, profilePhotoIsChanged: true)));
  }

  void setProfileImageOfMyHotel(FileModel file) {
    emit(state.copyWith(
        isLoading: false,
        error: null,
        myHotel: state.myHotel.copyWith(
            pathOfProfilePhoto: file.localPath, profilePhotoIsChanged: true)));
  }

  void setCategory(CategoryModel selectedCategory) {
    emit(state.copyWith(
        isLoading: false,
        error: null,
        location: state.location.copyWith(
          idCategory: selectedCategory.id,
        ),
        category: selectedCategory));
  }

  // bool wereChanges(
  //     {required String initialProfilePhotoOfLocation,
  //     required String initialProfilePhotoOfMyHotel,
  //     required int initialIdCategory,
  //     required List<FileModel> initialFiles,
  //     required String currentName,
  //     required String currentDescription,
  //     required String initName,
  //     required String initDescription}) {
  //   bool _isExistsEditedFiles(List<FileModel> files) {
  //     for (var file in files) {
  //       if (file.isEdited) {
  //         return true;
  //       }
  //     }
  //     return false;
  //   }
  //
  //   return (!deepComparing(initialFiles, state.files) ||
  //       _isExistsEditedFiles(state.files) ||
  //       currentName != initName ||
  //       currentDescription != initDescription ||
  //       initialProfilePhotoOfLocation != state.location.pathOfProfilePhoto ||
  //       initialProfilePhotoOfMyHotel != state.myHotel.pathOfProfilePhoto ||
  //       initialIdCategory != state.category.id);
  // }

  List<FileModel> get fileModels => state.files;
  //Function deepComparing = const DeepCollectionEquality().equals;
}
