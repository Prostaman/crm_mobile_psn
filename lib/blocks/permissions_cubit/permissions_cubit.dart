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

  Future<void> fetchPermissionsForCamera() async {
    emit(LoadingState());
    cameraStatus = await Permission.camera.request();
    microphoneStatus = await Permission.microphone.request();
    // locationStatus =
    await Permission.location.request();
    emit(SuccessPermissionState());
  }

  Future<MyPermissionStatus> checkPermissionsForCamera() async {
    debugPrint('checkPermissionsForCamera');
    await fetchPermissionsForCamera();
    bool flag = false;
    if (cameraStatus.isGranted && microphoneStatus.isGranted
        //&& locationStatus.isGranted
        ) {
      await fetchPermissionsForCamera();
      return MyPermissionStatus.Granted;
    }
    if (cameraStatus.isRestricted || cameraStatus.isPermanentlyDenied || cameraStatus.isDenied) {
      return MyPermissionStatus.DeniedCamera;
    } else {
      cameraStatus = await Permission.camera.request();
      flag = true;
    }
    if (microphoneStatus.isRestricted || microphoneStatus.isPermanentlyDenied || microphoneStatus.isDenied) {
      return MyPermissionStatus.DeniedMicrophone;
    } else {
      microphoneStatus = await Permission.microphone.request();
      flag = true;
    }
    // if (locationStatus.isRestricted || locationStatus.isPermanentlyDenied || locationStatus.isDenied) {
    //   return MyPermissionStatus.DeniedLocation;
    // }
    // else{
    //   locationStatus = await Permission.location.request();
    //   flag = true;
    // }

    if (flag) {
      return MyPermissionStatus.Undetermined;
    }
  }

  Future<void> makePermissionRequestAndroidPhotos() async {
    debugPrint('madePermissionRequestAndroidPhotos');
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    if (androidInfo.version.sdkInt <= 32) {
      galleryStatus = await Permission.storage.request();
    } else {
      galleryStatus = await Permission.photos.request();
    }
  }

  Future<void> fetchPermissionsForGallery() async {
    emit(LoadingState());

    if (Platform.isIOS) {
      galleryStatus = await Permission.photos.request();
    } else {
      await makePermissionRequestAndroidPhotos();
    }

    emit(SuccessPermissionState());
  }

  Future<MyPermissionStatus> checkPermissionsForGallery() async {
    await fetchPermissionsForGallery();
    bool flag = false;
    if (galleryStatus.isGranted && galleryStatus.isGranted
        //&& locationStatus.isGranted
        ) {
      await fetchPermissionsForGallery();
      return MyPermissionStatus.Granted;
    }
    if (galleryStatus.isRestricted || galleryStatus.isPermanentlyDenied || galleryStatus.isDenied) {
      return MyPermissionStatus.DeniedGallery;
    } else {
      if (Platform.isIOS) {
        galleryStatus = await Permission.photos.request();
      } else {
        await makePermissionRequestAndroidPhotos();
      }
      flag = true;
    }

    if (flag) {
      return MyPermissionStatus.Undetermined;
    }
  }

//   bool get permissionGranted {
//     if (cameraStatus.isGranted && microphoneStatus.isGranted
//     //&& locationStatus.isGranted
//     ) {
//       return true;
//     }

//     return false;
//   }
}

class SuccessPermissionState extends BaseCubitState {}
