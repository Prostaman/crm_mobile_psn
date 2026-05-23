import 'package:equatable/equatable.dart';

import '../../../../data/models/entities_database/file_model.dart';
import '../../../../data/models/entities_database/location_model.dart';
import '../../../../data/models/response_models/base_model.dart';

class LocationState extends BaseModel with EquatableMixin {
  final LocationModel location;
  final List<FileModel> files;
  final double percentLoaded;
  final String categoryDescription;

  LocationState({
    required this.location,
    required this.files,
    required this.percentLoaded,
    required this.categoryDescription,
  });

  @override
  dynamic get baseId => location.localId;

  @override
  List<Object?> get props => [
        location.localId,
        location.name,
        location.createdAt,
        location.idCategory,
        location.pathOfProfilePhoto,
        location.profilePhotoIsChanged,
        ...files.map((f) => [f.localId, f.localPath, f.synced, f.isEdited]),
        percentLoaded,
      ];
}
