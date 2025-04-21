import 'dart:io';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FileUtility {
  static Future<void> deleteFile(String localPath) async {
    try {
      final removingFile = File(localPath);
      if (await removingFile.exists()) {
        await removingFile.delete();
        debugPrint('File deleted successfully.');
      } else {
        debugPrint('File does not exist at path: $localPath');
      }
    } catch (e) {
      await FirebaseCrashlytics.instance.log("deleteFile $e");
      await FirebaseCrashlytics.instance.recordFlutterError(FlutterErrorDetails(exception: e));
      //throw e;
    }
  }

  static Future<String> moveFile(File file, String newLocalPath) async {
    String oldPath = file.path;
    // Формируем новый путь файла, включая новую директорию
    String newFilePath = newLocalPath + '/${DateFormat('yyyyMMddHHmmss').format(DateTime.now())}_' + file.path.split('/').last;

    try {
      // Получаем новый файл
       final newFile = File(newFilePath);

      // // Создаем родительскую директорию, если она не существует
       await newFile.create(recursive: true);
     
      // Копируем файл в новый путь
      await file.copy(newFilePath);

      // Удаляем исходный файл
      await file.delete();

      debugPrint('Файл успешно перемещен в $newFilePath');
      return newFilePath;
    } catch (e) {
      debugPrint('Ошибка при перемещении файла: $e');
      await FirebaseCrashlytics.instance.log("Ошибка при перемещении файла: $e");
      await FirebaseCrashlytics.instance.recordFlutterError(FlutterErrorDetails(exception: e));
      return oldPath;
    }
  }

  // Future<void> deleteAllFiles(String exampleLocalPath) async {
  //   if (Platform.isAndroid) {
  //     var availablePath = exampleLocalPath.substring(0, exampleLocalPath.lastIndexOf('/'));
  //     try {
  //       await deleteContents(availablePath);
  //       debugPrint('Директория удалена успешно.');
  //     } catch (e) {
  //       await FirebaseCrashlytics.instance.log("'Ошибка при перемещении файла: $e");
  //       await FirebaseCrashlytics.instance.recordFlutterError(FlutterErrorDetails(exception: e));
  //     }
  //   } else if (Platform.isIOS) {
  //     int lastIndex = exampleLocalPath.lastIndexOf('/');
  //     if (lastIndex != -1) {
  //       int secondLastIndex = exampleLocalPath.lastIndexOf('/', lastIndex - 1);
  //       if (secondLastIndex != -1) {
  //         var cameraPath = exampleLocalPath.substring(0, secondLastIndex);
  //         try {
  //           await deleteContents(cameraPath);
  //           debugPrint('Директория удалена успешно.');
  //         } catch (e) {
  //           await FirebaseCrashlytics.instance.log('deleteAllFiles Ошибка при удалении директории: $e');
  //           await FirebaseCrashlytics.instance.recordFlutterError(FlutterErrorDetails(exception: e));
  //         }
  //       } else {
  //         debugPrint("В строке нет предпоследнего символа '/'");
  //         await FirebaseCrashlytics.instance
  //             .recordFlutterError(FlutterErrorDetails(exception: Exception(['deleteAllFiles В строке нет предпоследнего символа /'])));
  //       }
  //     } else {
  //       await FirebaseCrashlytics.instance.recordFlutterError(FlutterErrorDetails(exception: Exception(["В строке нет символа '/'"])));
  //     }
  //   }
  // }

  // Future<void> deleteContents(String path) async {
  //   var dir = Directory(path);
  //   // Получаем список содержимого директории
  //   var contents = dir.listSync();
  //   // Проходимся по содержимому
  //   for (var fileOrDir in contents) {
  //     // Если это файл, удаляем его
  //     if (fileOrDir is File) {
  //       await fileOrDir.delete();
  //     }
  //     // Если это директория, рекурсивно вызываем deleteContents для неё
  //     else if (fileOrDir is Directory) {
  //       await deleteContents(fileOrDir.path);
  //     }
  //   }
  // }

  Future<DateTime?> getFileCreationDate(String filePath) async {
    try {
      File file = File(filePath);
      if (await file.exists()) {
        FileStat fileStat = await file.stat();
        return fileStat.changed; // You can also use .accessed or .modified for different timestamps
      } else {
        debugPrint('getFileCreationDate File not found');
        return null;
      }
    } catch (e) {
      debugPrint('getFileCreationDate Error: $e');
      return null;
    }
  }
}
