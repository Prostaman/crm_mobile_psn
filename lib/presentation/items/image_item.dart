import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:psn.hotels.hub/infrastructure/images.gen.dart';
import 'dart:io';

import 'package:psn.hotels.hub/presentation/ui_helper.dart';

class ImageItem extends StatelessWidget {
  final String imagePath;
  final BoxFit fit;
  final FilterQuality filterQuality;
  final double borderRadius;
  const ImageItem(
      {Key? key,
      required this.imagePath,
      this.fit = BoxFit.cover,
      this.filterQuality = FilterQuality.high,
      this.borderRadius = 10})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: _buildImage(),
    );
  }

  Widget _buildImage() {
    return Image.file(
      File(imagePath),
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      filterQuality: filterQuality,
      errorBuilder: (context, error, stackTrace) {
        String errorMessage =
            "Showing image, File not exists or error: $imagePath";
        debugPrint(errorMessage);
        FirebaseCrashlytics.instance
            .recordFlutterError(FlutterErrorDetails(exception: errorMessage));

        return Container(
          color: const Color.fromRGBO(255, 244, 244, 1), // Placeholder color
          width: double.infinity,
          height: double.infinity,
          child: Center(
            child: Wrap(
              children: [
                Column(
                  children: [
                    SvgPicture.asset(IMG.icons.noImageError,
                        fit: BoxFit.scaleDown),
                    const SizedBox(height: 6),
                    Text(
                      "Файл не найден",
                      textAlign: TextAlign.center,
                      style: textStyle(color: Colors.black, size: 10.0),
                    )
                  ],
                )
              ],
            ),
          ),
        );
      },
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: frame != null
              ? SizedBox.expand(child: child)
              : const SizedBox.expand(
                  child: Center(child: CircularProgressIndicator()),
                ),
        );
      },
    );
  }
}
