import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:psn.hotels.hub/helpers/gallery_saver_wrapper.dart';
import 'package:psn.hotels.hub/helpers/images.gen.dart';
import 'package:psn.hotels.hub/helpers/location_helper.dart';
import 'package:psn.hotels.hub/helpers/ui_helper.dart';
import 'package:psn.hotels.hub/models/entities_database/file_model.dart';
import 'package:psn.hotels.hub/models/response_models/file_model_response.dart';
import 'package:psn.hotels.hub/services/service_container.dart';
import 'package:video_compress/video_compress.dart';
import 'package:open_file/open_file.dart';
import 'package:sensors/sensors.dart';
import 'focus_circle_widget.dart';
import 'grid_widget.dart';
import 'package:collection/collection.dart';

import 'zoom_circle_widget.dart';

class CustomCameraScreen extends StatefulWidget {
  final List<CameraDescription>? cameras;
  CustomCameraScreen({required this.cameras});

  @override
  _CustomCameraScreenState createState() => _CustomCameraScreenState();
}

class _CustomCameraScreenState extends State<CustomCameraScreen> {
  CameraController? _cameraController;
  CameraDescription? _currentCamera;
  Future<void>? _initializeCameraControllerFuture;

  int _selectedIndex = 1;
  bool _recording = false;
  Timer? _timer;
  DateTime? _dateTimeStartRecord;
  bool _loading = false;

  List<FileModel> files = [];
  bool isLoadingMiniPhoto = false;
  //zoom
  double _currentScale = 1.0;
  double _baseScale = 1.0;
  double maxZoomLevel = 1;
  double minZoomLevel = 1;
  //manual focusing
  bool showFocusCircle = false;
  double x = 0;
  double y = 0;
  //switching camera
  //CameraController? _previousController;
  //CameraDescription? backCamera;
  List<CameraDescription> listOfBackCameras = [];
  CameraDescription? frontCamera;
  //Quality
  var quality = ServiceContainer().settingsService.qualityOfFiles;
  //Rotation
  late StreamSubscription<AccelerometerEvent> _accelerometerSubscription;
  ResolutionPreset get resolutionPreset {
    if (quality == 0) {
      debugPrint('ResolutionPreset.high');
      return ResolutionPreset.high;
    } else if (quality == 1) {
      debugPrint('ResolutionPreset.veryHigh');
      return ResolutionPreset.veryHigh;
    } else if (quality == 2) {
      debugPrint('ResolutionPreset.ultraHigh');
      return ResolutionPreset.ultraHigh;
    } else {
      debugPrint('ResolutionPreset.max');
      return ResolutionPreset.max;
    }
  }

  bool isPhotoMode = true;
  DeviceOrientation currentOrientation = DeviceOrientation.portraitUp;
  bool showGrid = false;
  int _currentIndexOfCamera = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  initState() {
    super.initState();
    if (widget.cameras != null) {
      for (var camera in widget.cameras!) {
        if (camera.lensDirection == CameraLensDirection.front) {
          frontCamera = camera;
          break;
        }
      }
      listOfBackCameras.clear();
      for (var camera in widget.cameras!) {
        if (camera.lensDirection == CameraLensDirection.back) {
          listOfBackCameras.add(camera);
          //backCamera = camera;
        }
      }
    }
    debugPrint("listOfBackCameras.length:${listOfBackCameras.length}");
    _initializeCameraControllerFuture = initCamera(0);
    initRotation();
  }

  int turns = 0;
  Future<void> initRotation() async {
    double degreeForRotation = Platform.isAndroid ? 1 : 8;
    _accelerometerSubscription = accelerometerEvents.listen((AccelerometerEvent event) async {
      if (_cameraController != null) {
        DeviceOrientation newOrientation = currentOrientation;
        if (event.y > degreeForRotation) {
          newOrientation = DeviceOrientation.portraitUp;
          turns = 0;
          //  print("DeviceOrientation.portraitUp");
        } else if (event.y < -1.0 * degreeForRotation) {
          newOrientation = DeviceOrientation.portraitDown;
          turns = 2;
          //  print("DeviceOrientation.portraitDown");
        } else if (event.x > degreeForRotation) {
          newOrientation = DeviceOrientation.landscapeLeft;
          // print("DeviceOrientation.landscapeLeft");
          turns = 1;
        } else if (event.x < -1.0 * degreeForRotation) {
          newOrientation = DeviceOrientation.landscapeRight;
          turns = 3;
          //  print("DeviceOrientation.landscapeRight");
        }
        if (currentOrientation != newOrientation) {
          currentOrientation = newOrientation;
          if (_cameraController != null) {
            await _cameraController!.lockCaptureOrientation(currentOrientation);
            setState(() {});
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _timer?.cancel();
    _accelerometerSubscription.cancel();
    super.dispose();
  }

  void startTimer() {
    _timer = new Timer.periodic(
      const Duration(seconds: 1),
      (Timer timer) {
        if (_recording == false) {
          setState(() {
            timer.cancel();
          });
        } else {
          if (_printDuration(
                Duration(
                  milliseconds: (DateTime.now().millisecondsSinceEpoch - _dateTimeStartRecord!.millisecondsSinceEpoch),
                ),
              ) ==
              "00:00:30") {
            _stopRecording();
          } else {
            setState(() {
              debugPrint("tick");
            });
          }
        }
      },
    );
  }

  Future<void> initCamera(int indexOfCamera) async {
    setState(() {
      _currentScale = 1;
      _loading = true;
    });
    //_currentCamera = widget.cameras?.first;
    //_currentCamera = frontCamera;
    _currentCamera = listOfBackCameras[indexOfCamera];
    _cameraController = CameraController(_currentCamera!, resolutionPreset);
    await _cameraController!.initialize();
    maxZoomLevel = await _cameraController!.getMaxZoomLevel();
    minZoomLevel = await _cameraController!.getMinZoomLevel();
    debugPrint('widget.cameras.length:${widget.cameras?.length}, maxZoomLevel:$maxZoomLevel, minZoomLevel:$minZoomLevel');
    setState(() {
      _currentIndexOfCamera = indexOfCamera;
      _loading = false;
    });
  }

  switchCamera() async {
    if (_currentCamera!.lensDirection == CameraLensDirection.front) {
      _currentCamera = listOfBackCameras[0];
      //print("switched to backCamera");
    } else {
      _currentCamera = frontCamera;

      ///print("switched to frontCamera");
    }

    if (isPhotoMode) {
      _cameraController = CameraController(_currentCamera!, resolutionPreset);
    } else {
      _cameraController = CameraController(_currentCamera!, ResolutionPreset.high);
    }
    setState(() {
      _loading = true;
    });
    await _cameraController!.initialize();
    maxZoomLevel = await _cameraController!.getMaxZoomLevel();
    minZoomLevel = await _cameraController!.getMinZoomLevel();
    setState(() {
      _loading = false;
    });
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _baseScale = _currentScale;
  }

  Future<void> _onScaleUpdate(ScaleUpdateDetails details) async {
    if (details.pointerCount >= 2 && _cameraController != null) {
      double newScale = double.parse((_baseScale * details.scale).clamp(minZoomLevel, maxZoomLevel).toStringAsFixed(1));
      _currentScale = newScale;
      await _cameraController!.setZoomLevel(_currentScale);
      setState(() {});
    }
  }

  void _takePicture(BuildContext context) async {
    try {
      if (_selectedIndex == 1) {
        setState(() {
          _loading = true;
        });
        var xfile = await _cameraController?.takePicture();
        _addFileFromXFile(xfile: xfile!, type: FileModelType.Image);
        setState(() {
          _loading = false;
        });
      } else {
        if (_recording == false) {
          _accelerometerSubscription.cancel();

          await _cameraController?.startVideoRecording();
          setState(() {
            _dateTimeStartRecord = DateTime.now();
            startTimer();
            _recording = true;
          });
        } else if (_recording == true) {
          await _stopRecording();
          // print("New video path:${xfile.path}");
        }
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> _stopRecording() async {
    setState(() => _loading = true);
    await _cameraController?.stopVideoRecording().then((xfile) {
      _loading = false;
      _addFileFromXFile(xfile: xfile, type: FileModelType.Video);
      initRotation();
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return WillPopScope(
        onWillPop: () async {
          if (files.isNotEmpty) {
            bool? result = await showDialog<bool>(
              context: context,
              builder: (context) {
                return AlertDialog(
                    surfaceTintColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    titlePadding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 0),
                    title: Text(
                      "Вы уверены что хотите выйти без сохранения?" + (isLoadingMiniPhoto ? " Последний файл ещё не сохранился." : ""),
                      style: textStyle(size: 18, weight: FontWeight.w300, color: ColorTextBlackAlertDialog),
                      textAlign: TextAlign.center,
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context, true);
                        },
                        child: Text("Выйти", style: textStyle(size: 18, weight: FontWeight.w400, color: ColorTextBlackAlertDialog)),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context, false);
                        },
                        child: Text("Cохранить", style: textStyle(size: 18, weight: FontWeight.w400, color: ColorTextOrange)),
                      ),
                    ]);
              },
            );
            if (result == null) {
              result = false;
            }
            if (result == false) {
              _complitePicker();
            }
            return result;
          } else {
            return true;
          }
        },
        child: Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: (_selectedIndex == 0)
                ? Text(
                    (_recording == true && _dateTimeStartRecord != null)
                        ? _printDuration(
                            Duration(
                              milliseconds: (DateTime.now().millisecondsSinceEpoch - _dateTimeStartRecord!.millisecondsSinceEpoch),
                            ),
                          )
                        : "00:00:00",
                    style: textStyle(color: ColorWhite),
                  )
                : Container(),
            actions: [
              widgetFlashMode(),
              IconButton(
                  icon: Icon(showGrid ? Icons.grid_on : Icons.grid_off), // Use the 'grid_on' icon
                  onPressed: () {
                    setState(() => showGrid = !showGrid);
                  })
            ],
            backgroundColor: Colors.black,
            iconTheme: IconThemeData(color: Colors.white),
          ),
          backgroundColor: Colors.black,
          body: FutureBuilder(
            future: _initializeCameraControllerFuture,
            builder: (context, snapshot) {
              return (snapshot.connectionState == ConnectionState.done)
                  ? GestureDetector(
                      onScaleUpdate: _onScaleUpdate,
                      onScaleStart: _handleScaleStart,
                      onTapUp: (details) {
                        _onTap(details);
                      },
                      onHorizontalDragEnd: (DragEndDetails details) async {
                        if (details.primaryVelocity! > 0) {
                          //жест слева направо
                          if (_currentIndexOfCamera > 0) {
                            _currentIndexOfCamera--;
                            await initCamera(_currentIndexOfCamera);
                          }
                        } else {
                          //жест справа налево
                          if (_currentIndexOfCamera < listOfBackCameras.length - 1) {
                            _currentIndexOfCamera++;
                            await initCamera(_currentIndexOfCamera);
                          }
                        }
                      },
                      child: Stack(
                        children: [
                          Stack(children: [
                            Container(
                              width: size.width,
                              height: size.height,
                              child: Align(
                                alignment: Alignment.center,
                                child: RotatedBox(
                                  quarterTurns: turns,
                                  child: CameraPreview(_cameraController!),
                                ),
                              ),
                            ),
                            showGrid ? GridOverlay() : Container()
                          ]),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: _buildFooterPortrait(),
                          ),
                          if (showFocusCircle) showCircle(x, y),
                          _loading == true ? DefaultFullScreenIndicator : Container()
                        ],
                      ))
                  : Center(child: CircularProgressIndicator());
            },
          ),
        ));
  }

  Future<void> _onTap(TapUpDetails details) async {
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      showFocusCircle = true;
      x = details.localPosition.dx;
      y = details.localPosition.dy;

      double fullWidth = MediaQuery.of(context).size.width;
      double cameraHeight = fullWidth * _cameraController!.value.aspectRatio;

      double xp = x / fullWidth;
      double yp = y / cameraHeight;

      Offset point = Offset(xp, yp);

      if ((point.dx < 0 || point.dx > 1 || point.dy < 0 || point.dy > 1)) {
        print('The values of point should be anywhere between (0,0) and (1,1).');
        return;
      }
      print("point : $point");
      // Manually focus
      await _cameraController?.setFocusPoint(point);

      // Manually set light exposure
      await _cameraController?.setExposurePoint(point);

      setState(() {
        Future.delayed(const Duration(seconds: 2)).whenComplete(() {
          setState(() {
            showFocusCircle = false;
          });
        });
      });
    }
  }

  Widget widgetFlashMode() {
    String _flashIconPath;
    if (_cameraController?.value.flashMode == FlashMode.always) {
      _flashIconPath = IMG.icons.cameraFlashOnPNG;
    } else if (_cameraController?.value.flashMode == FlashMode.torch) {
      _flashIconPath = IMG.icons.cameraFlashLight;
    } else if (_cameraController?.value.flashMode == FlashMode.auto) {
      _flashIconPath = IMG.icons.cameraFlashAutoPNG;
    } else {
      _flashIconPath = IMG.icons.cameraFlashOffPNG;
    }

    return Container(
      width: 60,
      child: IconButton(
        padding: const EdgeInsets.all(0),
        icon: SvgPicture.asset(_flashIconPath,
            // color: ColorWhite,
            colorFilter: ColorFilter.mode(ColorWhite, BlendMode.srcIn),
            width: 26,
            height: 26,
            fit: BoxFit.scaleDown),
        onPressed: () async {
          FlashMode newFlashMode;
          switch (_cameraController?.value.flashMode) {
            case FlashMode.auto:
              newFlashMode = FlashMode.off;
              break;
            case FlashMode.off:
              newFlashMode = FlashMode.always;
              break;
            case FlashMode.always:
              newFlashMode = FlashMode.torch;
              break;
            case FlashMode.torch:
              newFlashMode = FlashMode.auto;
              break;
            default:
              newFlashMode = FlashMode.off;
          }
          await onSetFlashModeButtonPressed(newFlashMode);
        },
      ),
    );
  }

  Widget _buildFooterPortrait() {
    double radiusOfImage = 30;
    return Column(children: [
      _currentCamera != frontCamera
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: listOfBackCameras.mapIndexed((index, item) {
                return Row(
                  children: [
                    index == _currentIndexOfCamera
                        ? zoomCircle(_currentScale)
                        : InkWell(
                            onTap: () async {
                              await initCamera(index);
                            },
                            child: Container(
                                width: 40,
                                height: 40,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.black45,
                                ),
                                child: CircleAvatar(
                                  radius: 3.0,
                                  backgroundColor: Colors.white,
                                )),
                          ),
                    SizedBox(width: 10),
                  ],
                );
              }).toList())
          : zoomCircle(_currentScale),
      SizedBox(height: 8),
      Container(
        color: Colors.black45,
        child: Column(
          children: [
            SizedBox(width: 6),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      if (!isLoadingMiniPhoto) {
                        _complitePicker();
                      }
                    },
                    child: files.length != 0
                        ? Container(
                            decoration: BoxDecoration(
                              color: isLoadingMiniPhoto == false ? Colors.orange : Colors.grey,
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                "Добавить (${files.length})",
                                style: textStyle(color: ColorWhite, size: 12),
                                textAlign: TextAlign.start,
                              ),
                            ),
                          )
                        : Container(),
                  ),
                ),
                Expanded(child: _selectedIndex == 1 ? textButtonModePhoto() : textButtonModeVideo()),
                Expanded(child: _selectedIndex == 1 ? textButtonModeVideo() : textButtonModePhoto()),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 120,
                  child: !isLoadingMiniPhoto
                      ? files.isNotEmpty
                          ? GestureDetector(
                              onTap: () {
                                OpenFile.open(files.last.localPath);
                              },
                              child: CircleAvatar(
                                radius: radiusOfImage,
                                backgroundColor: Colors.transparent,
                                child: ClipOval(
                                  child: SizedBox(
                                    width: radiusOfImage * 2,
                                    height: radiusOfImage * 2,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Center(
                                          child: CircularProgressIndicator(
                                            color: Color.fromARGB(255, 253, 216, 53),
                                          ),
                                        ),
                                        Image.file(
                                          File(
                                            files.last.type == FileModelType.Video ? (files.last.thumb ?? "") : files.last.localPath,
                                          ),
                                          width: radiusOfImage * 2,
                                          height: radiusOfImage * 2,
                                          fit: BoxFit.cover,
                                          errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
                                            return Center(
                                              child: Icon(Icons.error),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : null
                      : Center(child: CircularProgressIndicator(color: Color.fromARGB(255, 253, 216, 53))),
                ),
                Container(
                  width: 90,
                  child: Center(
                    child: InkWell(
                      onTap: () {
                        _takePicture(context);
                      },
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(35),
                          border: Border.all(color: ColorWhite, width: 6),
                        ),
                        padding: EdgeInsets.all(_recording == true ? 10 : 3),
                        child: Container(
                          decoration: BoxDecoration(
                            color: (_selectedIndex == 0) ? Colors.red : ColorWhite,
                            borderRadius: BorderRadius.circular(_recording == true ? 10 : 35),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 120,
                  //icon for switching camera
                  child: (widget.cameras != null && (widget.cameras?.length ?? 0) >= 2)
                      ? Center(
                          child: InkWell(
                            onTap: () {
                              switchCamera();
                            },
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.black87,
                                borderRadius: BorderRadius.circular(25),
                              ),
                              padding: const EdgeInsets.all(10),
                              child: Center(
                                child: Image.asset(
                                  IMG.icons.reverseCameraPNG,
                                  color: ColorWhite,
                                ),
                              ),
                            ),
                          ),
                        )
                      : null,
                ),
              ],
            ),
            SizedBox(height: 30),
          ],
        ),
      )
    ]);
  }

  Widget textButtonModePhoto() {
    return TextButton(
      onPressed: () async {
        if (_currentCamera != null) {
          _cameraController = CameraController(_currentCamera!, resolutionPreset);
          setState(() => _loading = true);
          if (_cameraController != null) {
            await _cameraController!.initialize();
            await _cameraController!.lockCaptureOrientation(currentOrientation);
            isPhotoMode = true;
          }
          _loading = false;
          _onItemTapped(1);
        }
      },
      child: Text(
        'ФОТО',
        style: textStyle(
          size: 14,
          color: _selectedIndex == 1 ? Colors.yellow[600] ?? Color.fromARGB(255, 253, 216, 53) : ColorWhite,
        ),
      ),
    );
  }

  Widget textButtonModeVideo() {
    return TextButton(
      onPressed: () async {
        isPhotoMode = false;
        if (resolutionPreset != ResolutionPreset.high) {
          //переключение качества камеры для видео
          _cameraController = CameraController(_currentCamera!, ResolutionPreset.high);
          setState(() => _loading = true);
          if (_cameraController != null) {
            await _cameraController!.initialize();
            await _cameraController!.lockCaptureOrientation(currentOrientation);
          }
          _loading = false;
        }
        if (Platform.isIOS && _cameraController != null) {
          _cameraController!.prepareForVideoRecording();
        }
        _onItemTapped(0);
      },
      child: Text(
        'ВИДЕО',
        style: textStyle(
          size: 14,
          color: _selectedIndex == 0 ? Colors.yellow[600] ?? Color.fromARGB(255, 253, 216, 53) : ColorWhite,
        ),
      ),
    );
  }

  Future<void> _addFileFromXFile({required XFile xfile, required FileModelType type}) async {
    setState(() => isLoadingMiniPhoto = true);
    try {
      if (type == FileModelType.Video) {
        _dateTimeStartRecord = null;
        _recording = false;
      }
      FileModel file = FileModel();
      file.localPath = xfile.path;
      file.createdAt = DateTime.now().toIso8601String();
      file.size = await xfile.length() / 1024;
      Position? position = LocationHelper.getCurrentPosition();

      if (position != null) {
        file.lat = position.latitude;
        file.long = position.longitude;
      }

      if (type == FileModelType.Image) {
        file.name = "image_" + xfile.name;
      } else if (type == FileModelType.Video) {
        try {
          if (Platform.isAndroid) {
            MediaInfo? mediaInfo;
            await Future.delayed(Duration(milliseconds: 200)); // задержка для избежания краша, когда к файлу будет обращаться Video Compressor
            // debugPrint("video123 File exists?:${await File(xfile.path).exists()}");
            //debugPrint("video123 before convert:${xfile.path}");
            mediaInfo = await VideoCompress.compressVideo(xfile.path, deleteOrigin: true);
            //debugPrint("video123 after convert:${mediaInfo!.path ?? ''}");
            var thumb = await VideoCompress.getFileThumbnail(mediaInfo!.path ?? '');
            file.thumb = thumb.path;
            file.localPath = mediaInfo.path ?? 'null';
          } else {
            var thumb = await VideoCompress.getFileThumbnail(file.localPath);
            file.thumb = thumb.path;
          }
        } catch (e) {
          //debugPrint("Error mini photo:$e");
          showSnackBar(context: context, message: "Не удалось создать превью видео");
        }
        file.name = "video_" + xfile.name;
      }
      files.add(file);
    } catch (e) {
      debugPrint("Error: $e");
      showSnackBar(context: context, message: e.toString());
    }
    setState(() => isLoadingMiniPhoto = false);
  }

  String _printDuration(Duration duration) {
    print(duration);
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  _complitePicker() {
    files.forEach((file) {
      saveFileToGallery(file);
    });
    setState(() => _loading = false);
    Navigator.pop(context, files);
  }

  Future<void> saveFileToGallery(FileModel file) async {
    try {
      GallerySaverWrapper gallerySaverWrapper = GallerySaverWrapper.instance;
      if (file.type == FileModelType.Image) {
        gallerySaverWrapper.saveImageToGallery(file.localPath);
      } else {
        gallerySaverWrapper.saveVideoToGallery(file.localPath);
      }
    } catch (e) {
      debugPrint("Saving to gallery: $e");
    }
  }

  Future<void> onSetFlashModeButtonPressed(FlashMode mode) async {
    setState(() => _loading = true);
    await setFlashMode(mode).then((_) {
      if (mounted) {
        setState(() => _loading = false);
      }
      // showInSnackBar('Flash mode set to ${mode.toString().split('.').last}');
    });
  }

  Future<void> setFlashMode(FlashMode mode) async {
    if (_cameraController == null) {
      return;
    }

    try {
      await _cameraController!.setFlashMode(mode);
    } on CameraException catch (e) {
      _showCameraException(e);
      rethrow;
    }
  }

  void _showCameraException(CameraException e) {
    _logError(e.code, e.description);
    showInSnackBar('Error: ${e.code}\n${e.description}');
  }

  void _logError(String code, String? message) {
    // ignore: avoid_print
    print('Error: $code${message == null ? '' : '\nError Message: $message'}');
  }

  void showInSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
