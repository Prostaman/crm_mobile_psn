import 'package:equatable/equatable.dart';
import '../../../models/response_models/base_model.dart';

class HotelSearchState extends BaseModel with EquatableMixin {
  final int id;
  final String name;
  final String country;
  final String resort;
  final bool isSelected;

  HotelSearchState(
      {required this.id,
      required this.name,
      required this.country,
      required this.resort,
      required this.isSelected});

  HotelSearchState copyWith({bool? isSelected}) {
    return HotelSearchState(
      id: id,
      name: name,
      country: country,
      resort: resort,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  @override
  dynamic get baseId => id;

  @override
  List<Object?> get props => [id, name, country, resort, isSelected];
}
