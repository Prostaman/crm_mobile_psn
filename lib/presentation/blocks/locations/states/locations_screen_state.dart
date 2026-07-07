import '../../../../data/models/entities_database/my_hotel_model.dart';
import '../../base_cubit/base_cubit.dart';
import 'location_state.dart';

class LocationsListSuccessState extends SuccessListState<LocationState> {
  final MyHotelModel myHotel;
  final int allFilesLength;
  final double percentLoadedFiles;

  LocationsListSuccessState({
    required super.models,
    required this.myHotel,
    required this.allFilesLength,
    required this.percentLoadedFiles,
  });

  LocationsListSuccessState copyWith({
    List<LocationState>? models,
    MyHotelModel? myHotel,
    int? allFilesLength,
    double? percentLoadedFiles,
  }) {
    return LocationsListSuccessState(
      models: models ?? this.models,
      myHotel: myHotel ?? this.myHotel,
      allFilesLength: allFilesLength ?? this.allFilesLength,
      percentLoadedFiles: percentLoadedFiles ?? this.percentLoadedFiles,
    );
  }

  @override
  List<Object?> get props => [
        ...models,
        myHotel.id,
        myHotel.description,
        myHotel.name,
        allFilesLength,
        percentLoadedFiles,
      ];
}
