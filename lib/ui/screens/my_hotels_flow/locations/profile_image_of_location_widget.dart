import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:psn.hotels.hub/helpers/images.gen.dart';
import 'package:psn.hotels.hub/models/entities_database/file_model.dart';
import 'package:psn.hotels.hub/models/entities_database/location_model.dart';
import 'package:psn.hotels.hub/models/response_models/file_model_response.dart';
import 'package:psn.hotels.hub/ui/items/image_item.dart';

Widget? profileImageOfLocation(int index, LocationModel location, List<List<FileModel>?> listOflistOfFiles) {
  if (location.pathOfProfilePhoto.isNotEmpty && File(location.pathOfProfilePhoto).existsSync()) {
    return ImageItem(imagePath: location.pathOfProfilePhoto);
  } else if ((listOflistOfFiles[index] ?? []).isEmpty) {
    return SvgPicture.asset(IMG.icons.noImageSVG, fit: BoxFit.scaleDown, width: 36, height: 36);
  } else {
    for (var file in listOflistOfFiles[index]!) {//find first image that not deleted and exists
      if (file.type == FileModelType.Video) {
        if (File(file.thumb ?? '').existsSync() && File(file.localPath).existsSync() && file.deleted != true) {
          return ImageItem(imagePath: file.thumb ?? '');
        }
      } else {
        if (File(file.localPath).existsSync() && file.deleted != true) {
          return ImageItem(imagePath: file.localPath);
        }
      }
    }
    return SvgPicture.asset(IMG.icons.noImageSVG, fit: BoxFit.scaleDown, width: 36, height: 36);
  }


  // return (listOflistOfFiles[index] ?? []).isEmpty || listOflistOfFiles[index]?.first.deleted == true
  //     ? SvgPicture.asset(IMG.icons.noImageSVG, fit: BoxFit.scaleDown, width: 36, height: 36)
  //     : listOflistOfFiles[index]?.first != null
  //         ? ImageItem(
  //             imagePath: listOflistOfFiles[index]!.first.type == FileModelType.Video
  //                 ? (listOflistOfFiles[index]!.first.thumb ?? "")
  //                 : listOflistOfFiles[index]!.first.localPath)
  //         : null;
}
