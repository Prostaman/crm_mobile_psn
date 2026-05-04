import 'package:equatable/equatable.dart';
import 'package:psn.hotels.hub/models/entities_database/category_of_location_model.dart';
import 'package:psn.hotels.hub/models/entities_database/location_model.dart';
import 'package:psn.hotels.hub/models/entities_database/my_hotel_model.dart';

import '../../../models/entities_database/file_model.dart';

class ContentState extends Equatable {
  final List<FileModel> files;
  final List<FileModel> visibleFiles;
  final Set<String> selectedIds;
  final MyHotelModel myHotel;
  final LocationModel location;
  final CategoryModel category;
  final List<CategoryModel> categories;

  final bool isLoading;
  final String? error;

  const ContentState({
    required this.files,
    this.visibleFiles = const [],
    required this.selectedIds,
    required this.myHotel,
    required this.location,
    required this.category,
    required this.categories,
    this.isLoading = false,
    this.error,
  });

  ContentState copyWith(
      {List<FileModel>? files,
      Set<String>? selectedIds,
      MyHotelModel? myHotel,
      LocationModel? location,
      CategoryModel? category,
      List<CategoryModel>? categories,
      bool? isLoading,
      String? error}) {
    final newFiles = files ?? this.files;
    return ContentState(
      files: files ?? this.files,
      visibleFiles: files != null
          ? newFiles.where((f) => !f.deleted).toList()
          : this.visibleFiles,
      selectedIds: selectedIds ?? this.selectedIds,
      myHotel: myHotel ?? this.myHotel,
      location: location ?? this.location,
      category: category ?? this.category,
      categories: categories ?? this.categories,
      isLoading: isLoading ?? this.isLoading,
      error: error, // важно: не ?? this.error
    );
  }

  // List<FileModel> get notDeletedFiles =>
  //     files.where((f) => !f.deleted).toList();

  @override
  List<Object?> get props => [
        ...files.map((e) => [
              e.localId,
              e.localPath,
              e.synced,
              e.syncError,
              e.isEdited,
              e.deleted
            ]),
        selectedIds,
        myHotel.id,
        myHotel.name,
        myHotel.pathOfProfilePhoto,
        location.localId,
        location.name,
        location.description,
        location.idCategory,
        location.pathOfProfilePhoto,
        ...categories.map((c) => [c.id, c.description]),
        category.id,
        isLoading,
        error,
      ];
}
