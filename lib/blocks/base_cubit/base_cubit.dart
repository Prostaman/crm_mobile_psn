import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:psn.hotels.hub/api/api_container.dart';
import 'package:psn.hotels.hub/models/response_models/base_model_response.dart';
import 'package:psn.hotels.hub/services/auth_service.dart';
import 'package:psn.hotels.hub/services/service_container.dart';

part 'base_state.dart';

part 'base_query.dart';

class BaseCubit extends Cubit<BaseCubitState> {
  BaseCubit(state) : super(state);

  ServiceContainer get services {
    return ServiceContainer();
  }

  AuthService get auth {
    return ServiceContainer().authService;
  }

  void catchError(Object e, [StackTrace? stackTrace]) {
    final message = mapError(e);

    emit(ErrorState(error: message));

    debugPrint(e.toString());
    FirebaseCrashlytics.instance.recordError(e, stackTrace);
  }

  String? mapError(Object e) {
    print(e);
    if (e is DioException) {
      if (e.error is SocketException) {
        return "Нет соединения с сервером.";
      }

      final response = e.response;

      if (response != null) {
        switch (response.statusCode) {
          case 413:
            return "File too large. Max size - 100 MB" +
                ApiEnvironment.getMaxFileSizeText();
          case 401:
            ServiceContainer().authService.authUserCubit.logout();
            return "Unauthorized";
          case 404:
            return "Page not found";
        }

        final data = response.data;

        if (data != null) {
          final parsed = JsonMapper.deserialize<BaseModelResponse>(data);

          if (parsed != null) {
            return _parsedBaseResponseModel(parsed);
          }
        }
      }

      return e.error?.toString() ?? "Network error";
    }

    if (e is BaseModelResponse) {
      return _parsedBaseResponseModel(e);
    }
    return "Unexpected error. $e";
  }

  String? _parsedBaseResponseModel(BaseModelResponse parsedJson) {
    if (parsedJson.errors.isNotEmpty) {
      var messages = "";
      for (var item in parsedJson.errors) {
        if (item.message.isNotEmpty) {
          messages += item.message;
          if (parsedJson.errors.last != item) {
            messages += "\n";
          }
        }
      }
      if (messages.isNotEmpty) {
        return messages;
      }
    }
    return null;
  }

// Future<List<FileModel>> sendFiles(List<FileModel> content, String path) async {
//   try {
//     content.removeWhere((element) => element == null);
//     if (content != null && content.length > 0) {
//       List<FileModel> alreadyUploaded = content.where((element) => (element.localPath == null)).toList();
//       List<FileModel> uploading = content.where((element) => (element.localPath != null)).toList();

//       List<FileResponse> sendedFiles = await Future.wait(uploading.map(
//         (e) => ApiContainer().filesApi.send(e, path),
//       ));
//       List<FileModel> uploaded = sendedFiles.map((response) {
//         response.model.sid = response.sid;

//         return response.model;
//       }).toList();

//       List<FileModel> allFiles = [];

//       allFiles.addAll(alreadyUploaded);
//       allFiles.addAll(uploaded);

//       var correctFiles = allFiles.where((element) => element.id != null).toList();

//       if (correctFiles != null && correctFiles.length > 0) {
//         return correctFiles;
//       }
//     }
//     return [];

//     // List<FileResponse> sendedFiles = await Future.wait(content.map(
//     //   (e) => ApiContainer().filesApi.send(e, path),
//     // ));
//     // return sendedFiles.map((response) {
//     //   return response;
//     // }).toList();
//   } catch (error) {
//     throw (error);
//   }
// }
}
