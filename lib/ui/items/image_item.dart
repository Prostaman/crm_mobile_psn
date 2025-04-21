import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:psn.hotels.hub/helpers/images.gen.dart';
import 'dart:io';

import 'package:psn.hotels.hub/helpers/ui_helper.dart';

class ImageItem extends StatelessWidget {
  final String imagePath;
  final BoxFit fit;
  final FilterQuality filterQuality;
  final double borderRadius;
  const ImageItem({Key? key, required this.imagePath, this.fit = BoxFit.cover, this.filterQuality = FilterQuality.high, this.borderRadius = 10})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: _buildImage(),
    );
  }

  Widget _buildImage() {
    // Create a File object with the specified path
    File file = File(imagePath);

    // Check if the file exists
    return FutureBuilder<bool>(
      future: file.exists(),
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // While waiting for the future to complete, display a progress indicator
          return Center(
            child: CircularProgressIndicator(),
          );
        } else if (snapshot.hasError || !snapshot.hasData) {
          String error = "Showing image error: ${snapshot.error}";
          debugPrint(error);
          FirebaseCrashlytics.instance.recordFlutterError(FlutterErrorDetails(exception: error));
          // If there's an error, display an error message
          return Container(
            color: Colors.grey, // Placeholder color
            width: 100, // Placeholder width
            height: 100, // Placeholder height
            child: Center(
              child: Text(
                snapshot.hasError ? "Error: ${snapshot.error}" : "Error",
                textAlign: TextAlign.center,
                style: textStyle(color: Colors.red),
              ),
            ),
          );
        } else if (snapshot.data == true) {
          // File exists, return the Image widget
          return Image.file(
            File(imagePath),
            fit: fit,
            filterQuality: filterQuality,
          );
        } else if (snapshot.data == false) {
          String error = "Showing image, File not exists";
          debugPrint(error);
          FirebaseCrashlytics.instance.recordFlutterError(FlutterErrorDetails(exception: error));
          // File does not exist, return a placeholder container
          return Container(
            color: Color.fromRGBO(255, 244, 244, 1), // Placeholder color
            width: 100, // Placeholder width
            height: 100, // Placeholder height
            child: Center(
                child: Wrap(
              children: [
                Column(children: [
                  SvgPicture.asset(IMG.icons.noImageError, fit: BoxFit.scaleDown),
                  SizedBox(height: 6),
                  Text(
                    "Файл не найден",
                    textAlign: TextAlign.center,
                    style: textStyle(color: Colors.black, size: 10.0),
                  )
                ])
              ],
            )),
          );
        } else {
          return Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }
}
