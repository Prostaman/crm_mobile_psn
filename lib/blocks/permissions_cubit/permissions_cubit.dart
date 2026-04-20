import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:psn.hotels.hub/blocks/base_cubit/base_cubit.dart';

enum MyPermissionStatus {
  Granted,
  Undetermined,
  DeniedCamera,
  DeniedMicrophone,
  DeniedLocation,
  DeniedGallery,
}

class PermissionsCubit extends Cubit<BaseCubitState> {
  PermissionStatus cameraStatus = PermissionStatus.denied;
  PermissionStatus microphoneStatus = PermissionStatus.denied;
  // PermissionStatus locationStatus=PermissionStatus.denied;
  PermissionStatus galleryStatus = PermissionStatus.denied;

  PermissionsCubit() : super(InitialState());

  Future<void> requestAllPermissions() async {
    List<Permission> permissions = [
      Permission.camera,
      Permission.microphone,
      Permission.location,
    ];

    if (Platform.isIOS) {
      permissions.add(Permission.photos);
    } else if (Platform.isAndroid) {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      if (androidInfo.version.sdkInt <= 32) {
        permissions.add(Permission.storage);
      } else {
        permissions.add(Permission.photos);
      }
    }

    await permissions.request();
  }

  Future<void> _fetchPermissionsForCamera() async {
    emit(LoadingState());
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.microphone,
      Permission.location,
    ].request();

    cameraStatus = statuses[Permission.camera] ?? PermissionStatus.denied;
    microphoneStatus =
        statuses[Permission.microphone] ?? PermissionStatus.denied;
    emit(SuccessPermissionState());
  }

  Future<MyPermissionStatus> checkPermissionsForCamera() async {
    debugPrint('checkPermissionsForCamera');
    await _fetchPermissionsForCamera();

    if (cameraStatus.isGranted && microphoneStatus.isGranted) {
      return MyPermissionStatus.Granted;
    }

    if (!cameraStatus.isGranted) {
      return MyPermissionStatus.DeniedCamera;
    }

    if (!microphoneStatus.isGranted) {
      return MyPermissionStatus.DeniedMicrophone;
    }

    return MyPermissionStatus.Undetermined;
  }

  Future<void> _makePermissionRequestAndroidPhotos() async {
    debugPrint('madePermissionRequestAndroidPhotos');
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    galleryStatus = await (androidInfo.version.sdkInt <= 32
        ? Permission.storage.request()
        : Permission.photos.request());
  }

  Future<void> _fetchPermissionsForGallery() async {
    emit(LoadingState());

    if (Platform.isIOS) {
      galleryStatus = await Permission.photos.request();
    } else {
      await _makePermissionRequestAndroidPhotos();
    }

    emit(SuccessPermissionState());
  }

  Future<MyPermissionStatus> checkPermissionsForGallery() async {
    debugPrint('checkPermissionsForGallery');
    await _fetchPermissionsForGallery();

    if (galleryStatus.isGranted) {
      return MyPermissionStatus.Granted;
    }

    if (galleryStatus.isRestricted ||
        galleryStatus.isPermanentlyDenied ||
        galleryStatus.isDenied) {
      return MyPermissionStatus.DeniedGallery;
    }

    return MyPermissionStatus.Undetermined;
  }
}

class SuccessPermissionState extends BaseCubitState {}
