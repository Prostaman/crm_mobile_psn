import '../../../../../blocks/files/states/files_screen_state.dart';
import 'package:collection/collection.dart';

extension FilesStateDiff on FilesState {
  bool isDifferentFrom(FilesState other) {
    return !const DeepCollectionEquality().equals(files, other.files) ||
        location.name != other.location.name ||
        location.description != other.location.description ||
        location.pathOfProfilePhoto != other.location.pathOfProfilePhoto ||
        myHotel.pathOfProfilePhoto != other.myHotel.pathOfProfilePhoto ||
        category.id != other.category.id ||
        files.any((f) => f.isEdited);
  }
}
