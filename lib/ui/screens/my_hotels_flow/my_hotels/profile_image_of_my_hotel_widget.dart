import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:psn.hotels.hub/helpers/images.gen.dart';
import 'package:psn.hotels.hub/models/entities_database/file_model.dart';
import 'package:psn.hotels.hub/models/entities_database/my_hotel_model.dart';
import 'package:psn.hotels.hub/models/response_models/file_model_response.dart';
import 'package:psn.hotels.hub/ui/items/image_item.dart';

Widget? profileImageOMyfHotel(MyHotelModel myHotel, List<FileModel> files) {
  print("myHotel.pathOfProfilePhoto:${myHotel.pathOfProfilePhoto}");
  if (myHotel.pathOfProfilePhoto.isNotEmpty && File(myHotel.pathOfProfilePhoto).existsSync()) {
    return ImageItem(imagePath: myHotel.pathOfProfilePhoto);
  } else if (files.isEmpty) {
    return SvgPicture.asset(IMG.icons.noImageSVG, fit: BoxFit.scaleDown, width: 36, height: 36);
  } else {
    for (var file in files) {
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
}
