import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:intl/intl.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class MediaEditorHelper {
  /// Generates a new file path in the same directory as the [oldPath]
  static String generateNewPath(String oldPath) {
    final directory = oldPath.substring(0, oldPath.lastIndexOf('/'));
    final timestamp = DateFormat('yyyyMMddHHmmss').format(DateTime.now());
    return "$directory/$timestamp.jpg";
  }

  /// Captures a widget identified by [globalKey] and returns its bytes as PNG
  static Future<Uint8List> captureWidgetToBytes(
      GlobalKey globalKey, double pixelRatio) async {
    final RenderRepaintBoundary? repaintBoundary =
        globalKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;

    if (repaintBoundary == null) throw Exception("RepaintBoundary not found");

    final ui.Image boxImage =
        await repaintBoundary.toImage(pixelRatio: pixelRatio);
    final ByteData? byteData =
        await boxImage.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null)
      throw Exception("Failed to convert image to ByteData");

    return byteData.buffer.asUint8List();
  }

  /// Handles image cropping and returns the path of the cropped file
  static Future<String?> cropImage(String sourcePath) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: sourcePath,
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 100,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: '',
          toolbarColor: Colors.deepOrange,
          toolbarWidgetColor: Colors.black,
          backgroundColor: Colors.black,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
          hideBottomControls: true,
        ),
        IOSUiSettings(
          title: '',
        ),
      ],
    );
    return croppedFile?.path;
  }

  /// Rotates an image and returns the path of the new file
  static Future<XFile?> rotateImage({
    required String sourcePath,
    required String targetPath,
    required int angle,
  }) async {
    return await FlutterImageCompress.compressAndGetFile(
      sourcePath,
      targetPath,
      rotate: angle,
      quality: 100,
    );
  }
}
