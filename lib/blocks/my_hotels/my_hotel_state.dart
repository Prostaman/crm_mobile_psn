import 'package:equatable/equatable.dart';
import '../../models/entities_database/file_model.dart';
import '../../models/entities_database/my_hotel_model.dart';
import '../../models/response_models/base_model.dart';

class MyHotelState extends BaseModel with EquatableMixin {
  final MyHotelModel base;
  final List<FileModel> files;
  final double percentUploaded;
  final String country;
  final String resort;

  MyHotelState({
    required this.base,
    required this.files,
    required this.percentUploaded,
    required this.country,
    required this.resort,
  });

  @override
  dynamic get baseId => base.id;

  @override
  List<Object?> get props => [
        base.id,
        files.length,
        percentUploaded,
        country,
        resort,
        base.createdAt,
        base.name,
        base.pathOfProfilePhoto,
        base.profilePhotoIsChanged,
      ];
}
