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

  catchError(final e) {
    emit(ErrorState(error: _catchError(e) ?? "Unknown error"));
    FirebaseCrashlytics.instance.log(e);
    FirebaseCrashlytics.instance.recordFlutterError(FlutterErrorDetails(exception: e));
  }

  String? _catchError(final e) {
    print(e);
    if (e is DioException) {
      if (e.error is SocketException) {
        return "Нет соединения с сервером.";
      }
      if (e.response != null) {
        if (e.response!.statusCode == 413) {
          return "File too large. Maximum file size - " + ApiEnvironment.getMaxFileSizeText();
        } else if (e.response!.statusCode == 401) {
          ServiceContainer().authService.authUserCubit.logout();
        } else if (e.response!.statusCode == 404) {
          return "Page not found";
        } else if (e.response!.data != null) {
          final parsedJson = JsonMapper.deserialize<BaseModelResponse>(e.response!.data);
          if (parsedJson != null) {
            return _parsedBaseResponseModel(parsedJson);
          }
        }
      } else if (e.error != null) {
        print(e.error.toString());
        return e.error.toString();
      }
    } else if (e is BaseModelResponse) {
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

  // Future<List<FileModel>> sendFiles(List<FileModel> files, String path) async {
  //   try {
  //     files.removeWhere((element) => element == null);
  //     if (files != null && files.length > 0) {
  //       List<FileModel> alreadyUploaded = files.where((element) => (element.localPath == null)).toList();
  //       List<FileModel> uploading = files.where((element) => (element.localPath != null)).toList();

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

  //     // List<FileResponse> sendedFiles = await Future.wait(files.map(
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
