import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:psn.hotels.hub/infrastructure/images.gen.dart';
import 'package:psn.hotels.hub/data/models/entities_database/file_model.dart';
import 'package:psn.hotels.hub/data/models/response_models/file_model_response.dart';
import 'package:psn.hotels.hub/presentation/items/image_item.dart';

class ProfileImageWidget extends StatelessWidget {
  final String pathOfProfilePhoto;
  final List<FileModel> files;

  const ProfileImageWidget({
    Key? key,
    required this.pathOfProfilePhoto,
    required this.files,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (pathOfProfilePhoto.isNotEmpty &&
        File(pathOfProfilePhoto).existsSync()) {
      return ImageItem(imagePath: pathOfProfilePhoto);
    }

    if (files.isEmpty) {
      return _buildNoImage();
    }

    for (var file in files) {
      if (file.deleted == true) continue;

      if (file.type == FileModelType.Video) {
        if (file.thumb != null &&
            file.thumb!.isNotEmpty &&
            File(file.thumb!).existsSync() &&
            File(file.localPath).existsSync()) {
          return ImageItem(imagePath: file.thumb!);
        }
      } else {
        if (File(file.localPath).existsSync()) {
          return ImageItem(imagePath: file.localPath);
        }
      }
    }

    return _buildNoImage();
  }

  Widget _buildNoImage() {
    return SvgPicture.asset(
      IMG.icons.noImageSVG,
      fit: BoxFit.scaleDown,
      width: 36,
      height: 36,
    );
  }
}
