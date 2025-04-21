import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
class PhotoUtility {
  static Future<String> rotateImage(String oldImagePath, num angle) async {
    final originalFile = File(oldImagePath);
    List<int> imageBytes = await originalFile.readAsBytes();
    final Uint8List uint8List = Uint8List.fromList(imageBytes);
    var originalImage = await compute(img.decodeImage, uint8List);
    img.Image fixedImage = originalImage!;
    OriginalImageAndAngle originalImageAndAngle = OriginalImageAndAngle(originalImage, angle);
    fixedImage = await compute((OriginalImageAndAngle originalImageAndAngle) {
      return img.copyRotate(originalImageAndAngle.originalImage, angle: originalImageAndAngle.angle);
    }, originalImageAndAngle);
    var encodedImageToJpg = await compute(img.encodeJpg, fixedImage);
   // await compute(originalFile.writeAsBytes, encodedImageToJpg);
       var availablePath = oldImagePath.substring(0, oldImagePath.lastIndexOf('/'));
    String newFilePath = "$availablePath/${DateFormat('yyyyMMddHHmmss').format(DateTime.now())}.jpg";
    await compute(File(newFilePath).writeAsBytes, encodedImageToJpg);
    return newFilePath;
  }
}

class OriginalImageAndAngle {
  final img.Image originalImage;
  final num angle;
  OriginalImageAndAngle(this.originalImage, this.angle);
}
