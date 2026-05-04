import 'package:flutter/cupertino.dart';
import '../../../../../blocks/content/states/content_state.dart';
import 'package:collection/collection.dart';

extension ContentStateDiff on ContentState {
  bool isDifferentFrom(ContentState other) {
    debugPrint("Comparing:"
        "\nDeepCollectionEquality().equals(files, other.files): ${const DeepCollectionEquality().equals(files, other.files)}"
        "\nlocation.name != other.location.name: ${location.name != other.location.name}"
        "\nlocation.description != other.location.description: ${location.description != other.location.description}"
        "\nlocation.pathOfProfilePhoto != other.location.pathOfProfilePhoto: ${location.pathOfProfilePhoto != other.location.pathOfProfilePhoto}"
        "\nmyHotel.pathOfProfilePhoto != other.myHotel.pathOfProfilePhoto: ${myHotel.pathOfProfilePhoto != other.myHotel.pathOfProfilePhoto}"
        "\ncategory.id != other.category.id : ${category.id != other.category.id}"
        "\nfiles.any((f) => f.isEdited) : ${files.any((f) => f.isEdited)}");

    return !const DeepCollectionEquality()
            .equals(visibleFiles, other.visibleFiles) ||
        location.name != other.location.name ||
        location.description != other.location.description ||
        location.pathOfProfilePhoto != other.location.pathOfProfilePhoto ||
        myHotel.pathOfProfilePhoto != other.myHotel.pathOfProfilePhoto ||
        category.id != other.category.id ||
        files.any((f) => f.isEdited);
  }
}
