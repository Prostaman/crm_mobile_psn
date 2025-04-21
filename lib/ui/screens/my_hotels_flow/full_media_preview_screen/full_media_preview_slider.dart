import 'dart:io';
import 'dart:typed_data';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:psn.hotels.hub/blocks/hotel_location/my_hotel_cubit.dart';
import 'package:psn.hotels.hub/helpers/file_utility.dart';
import 'package:psn.hotels.hub/helpers/images.gen.dart';
import 'package:psn.hotels.hub/helpers/rotating_image.dart';
import 'package:psn.hotels.hub/services/service_container.dart';
import 'package:psn.hotels.hub/ui/items/filters.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:psn.hotels.hub/helpers/ui_helper.dart';
import 'package:psn.hotels.hub/models/entities_database/file_model.dart';
import 'package:psn.hotels.hub/models/response_models/file_model_response.dart';
import 'package:video_player/video_player.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:ui' as ui;
import 'package:intl/intl.dart';
import 'package:image_cropper/image_cropper.dart';
import 'dart:math' as math;
import 'semi_circle.dart';

class FullMediaPreviewSlider extends StatefulWidget {
  final int initialPage;
  final PageController pageController;
  final MyHotelCubit _cubit;
  final VoidCallback setStateCallback;

  FullMediaPreviewSlider(this._cubit, this.setStateCallback, this.initialPage, this.pageController, {Key? key});

  @override
  _FullMediaPreviewSliderState createState() => _FullMediaPreviewSliderState();
}

class _FullMediaPreviewSliderState extends State<FullMediaPreviewSlider> {
  int currentIndexOfFile = 0;

  List<List<double>> filters = [NO_MATRIX, SEPIA_MATRIX, GREYSCALE_MATRIX, VINTAGE_MATRIX, SWEET_MATRIX];

  bool isFilterModeOn = false;
  int currentIndexOfFilter = 0;

  bool isRotatingMode = false;
  double angleOfRotating = 0;

  var quality = ServiceContainer().settingsService.qualityOfFiles;
  double get pixelRatio {
    //quality for filter
    if (quality == 0) {
      return 1;
    } else if (quality == 1) {
      return 4;
    } else {
      return 7;
    }
  }

  bool isLoading = false;

  @override
  void initState() {
    currentIndexOfFile = widget.initialPage;
    super.initState();
  }

  void onPageChanged(int index) {
    setState(() {
      //debugPrint('onPageChanged:$index');
      currentIndexOfFile = index;
      isFilterModeOn = false;
      currentIndexOfFilter = 0;
      isRotatingMode = false;
      angleOfRotating = 0;
    });
  }

  void overrideImage(String newFilePath) {
    widget._cubit.files[currentIndexOfFile].oldLocalPath = widget._cubit.files[currentIndexOfFile].localPath;
    widget._cubit.files[currentIndexOfFile].localPath = newFilePath;
    widget._cubit.files[currentIndexOfFile].synced = false;
    widget._cubit.files[currentIndexOfFile].isEdited = true;
  }

  final GlobalKey _globalKey = GlobalKey();
  Future<void> saveImageWithFiltersFromWidget() async {
    setState(() {
      isLoading = true;
    });
    RenderRepaintBoundary repaintBoundary = _globalKey.currentContext?.findRenderObject() as RenderRepaintBoundary;
    ui.Image boxImage = await repaintBoundary.toImage(pixelRatio: pixelRatio); // for saving quality
    ByteData? byteData = await boxImage.toByteData(format: ui.ImageByteFormat.png);
    Uint8List uint8list = byteData!.buffer.asUint8List();
    String oldFilePath = widget._cubit.files[currentIndexOfFile].localPath;
    var availablePath = oldFilePath.substring(0, oldFilePath.lastIndexOf('/'));
    String newFilePath = "$availablePath/${DateFormat('yyyyMMddHHmmss').format(DateTime.now())}.jpg";
    await File(newFilePath).writeAsBytes(uint8list);
    setState(() {
      overrideImage(newFilePath);
      isFilterModeOn = false;
      currentIndexOfFilter = 0;
      isLoading = false;
    });
  }

  Widget widgetCorouselOfFilters(List<Widget> widgets) {
    return Container(
      height: 80, // Высота карусели
      child: ListView.builder(
        scrollDirection: Axis.horizontal, // Горизонтальная прокрутка
        itemCount: filters.length,
        itemBuilder: (BuildContext context, int index) {
          return GestureDetector(
            onTap: () {
              setState(() {
                currentIndexOfFilter = index;
              });
            },
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: ColorFiltered(
                colorFilter: ColorFilter.matrix(filters[index]),
                child: widgets[currentIndexOfFile],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _cropImage() async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: widget._cubit.files[currentIndexOfFile].localPath,
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 100,
      uiSettings: [
        AndroidUiSettings(
            toolbarTitle: 'Cropper',
            toolbarColor: Colors.deepOrange,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
            hideBottomControls: true),
        IOSUiSettings(
          title: 'Cropper',
        ),
      ],
    );
    if (croppedFile != null) {
      if (Platform.isAndroid) {
        setState(() {
          overrideImage(croppedFile.path);
        });
      } else if (Platform.isIOS) {
        //print("New file path:${croppedFile.path}");
        String newPath = widget._cubit.files[currentIndexOfFile].localPath;
        overrideImage(await FileUtility.moveFile(File(croppedFile.path), newPath.substring(0, newPath.lastIndexOf('/'))));
        setState(() {});
      }
    }
  }

  List<Widget> widgets = [];
  List<FileModel> models = [];

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        // PopScope doesn't work for ios, so leave it
        onWillPop: () {
          widget.setStateCallback();
          return Future.value(true);
        },
        child: BlocBuilder(
            bloc: widget._cubit,
            builder: (context, state) {
              widgets.clear();
              models.clear();
              widget._cubit.files.forEach((fileModel) {
                if (fileModel.deleted == false) {
                  var file = File(fileModel.localPath);
                  if (file.existsSync()) {
                    if (fileModel.type == FileModelType.Image) {
                      widgets.add(Image.file(file));
                      models.add(fileModel);
                    } else if (fileModel.type == FileModelType.Video) {
                      widgets.add(
                        ChewieDemo(
                          file: fileModel,
                        ),
                      );
                      models.add(fileModel);
                    }
                    // debugPrint("length: ${models.length}");
                  }
                }
              });

              return Stack(
                children: [
                  Scaffold(
                    appBar: !isFilterModeOn && !isRotatingMode
                        ? AppBar(
                            backgroundColor: Color.fromRGBO(43, 54, 65, 1),
                            leadingWidth: 86,
                            centerTitle: true,
                            titleSpacing: 0,
                            leading: InkWell(
                              onTap: () {
                                widget.setStateCallback();
                                Navigator.pop(context);
                              },
                              child: Row(
                                children: [
                                  SizedBox(width: 16),
                                  SvgPicture.asset(IMG.icons.iconArrowBack,
                                      colorFilter: ColorFilter.mode(Colors.white, BlendMode.srcIn), fit: BoxFit.scaleDown),
                                ],
                              ),
                            ),
                            title: Text("${currentIndexOfFile + 1}/${models.length}", style: textStyle(color: Colors.white, size: 18)),
                            actions: [
                              IconButton(
                                icon: SvgPicture.asset(IMG.icons.iconDelete,
                                    width: 23, height: 26, colorFilter: ColorFilter.mode(Colors.white, BlendMode.srcIn), fit: BoxFit.scaleDown),
                                onPressed: () async {
                                  showDialog(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                          title: Text(
                                            "Удалить медиафайл?",
                                            style: textStyle(size: 18, weight: FontWeight.w300, color: ColorTextBlackAlertDialog),
                                          ),
                                          surfaceTintColor: Colors.white,
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                              },
                                              child:
                                                  Text("Нет", style: textStyle(size: 18, weight: FontWeight.w400, color: ColorTextBlackAlertDialog)),
                                            ),
                                            TextButton(
                                              onPressed: () async {
                                                await widget._cubit.deleteFile(models[currentIndexOfFile]);
                                                models.removeAt(currentIndexOfFile);
                                                currentIndexOfFile--;
                                                if (currentIndexOfFile == -1) {
                                                  currentIndexOfFile = 0;
                                                }

                                                if (models.length == 1) {
                                                  currentIndexOfFile = 0;
                                                }

                                                if (models.length == 0) {
                                                  widget.setStateCallback();
                                                  Navigator.pop(context);
                                                } else {
                                                  setState(() {});
                                                }

                                                Navigator.pop(context);
                                              },
                                              child: Text("Да", style: textStyle(size: 18, weight: FontWeight.w400, color: ColorTextOrange)),
                                            )
                                          ]);
                                    },
                                  );
                                },
                              ),
                              IconButton(
                                icon: SvgPicture.asset(
                                  IMG.icons.iconShare,
                                  width: 26,
                                  height: 26,
                                  colorFilter: ColorFilter.mode(Colors.white, BlendMode.srcIn),
                                ),
                                onPressed: ()  {
                                 Share.shareXFiles([XFile(models[currentIndexOfFile].localPath)]);
                                },
                              ),
                             widget._cubit.files[currentIndexOfFile].type==FileModelType.Image ? PopupMenuButton(
                                iconColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                                position: PopupMenuPosition.under,
                                itemBuilder: (BuildContext context) => [
                                  PopupMenuItem(
                                    child: Row(
                                      children: [
                                        SvgPicture.asset(
                                          IMG.icons.iconLocation,
                                          fit: BoxFit.scaleDown,
                                        ),
                                        SizedBox(width: 12),
                                        Text("Сделать главной фото в локации")
                                      ],
                                    ),
                                    value: 1,
                                  ),
                                  PopupMenuItem(
                                    child: Row(
                                      children: [
                                        SvgPicture.asset(
                                          IMG.icons.iconHotel,
                                          fit: BoxFit.scaleDown,
                                        ),
                                        SizedBox(width: 9),
                                        Text("Сделать главной в отеле")
                                      ],
                                    ),
                                    value: 2,
                                  ),
                                ],
                                onSelected: (value) {
                                  if (value == 1) {
                                    showDialog(
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                            title: Text(
                                              "Сделать фото главным в локации ${widget._cubit.locationModel.name}? ",
                                              style: textStyle(size: 18, weight: FontWeight.w300, color: ColorTextBlackAlertDialog),
                                            ),
                                            surfaceTintColor: Colors.white,
                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                },
                                                child: Text("Отменить",
                                                    style: textStyle(size: 18, weight: FontWeight.w400, color: ColorTextBlackAlertDialog)),
                                              ),
                                              TextButton(
                                                onPressed: () async {
                                                  widget._cubit.setProfileImageOfLocation(widget._cubit.files[currentIndexOfFile]);
                                                  Navigator.pop(context);
                                                },
                                                child: Text("Да", style: textStyle(size: 18, weight: FontWeight.w400, color: ColorTextOrange)),
                                              )
                                            ]);
                                      },
                                    );
                                  } else if (value == 2) {
                                    showDialog(
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                            title: Text(
                                              "Сделать фото главным в отеле ${widget._cubit.myHotelModel.name}? ",
                                              style: textStyle(size: 18, weight: FontWeight.w300, color: ColorTextBlackAlertDialog),
                                            ),
                                            surfaceTintColor: Colors.white,
                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                },
                                                child: Text("Отменить",
                                                    style: textStyle(size: 18, weight: FontWeight.w400, color: ColorTextBlackAlertDialog)),
                                              ),
                                              TextButton(
                                                onPressed: () async {
                                                  widget._cubit.setProfileImageOfMyHotel(widget._cubit.files[currentIndexOfFile]);
                                                  Navigator.pop(context);
                                                },
                                                child: Text("Да", style: textStyle(size: 18, weight: FontWeight.w400, color: ColorTextOrange)),
                                              )
                                            ]);
                                      },
                                    );
                                  }
                                },
                              ) : SizedBox()
                            ],
                          )
                        : null,
                    floatingActionButton: widget._cubit.files[currentIndexOfFile].type == FileModelType.Image
                        ? Padding(
                            padding: EdgeInsets.only(bottom: isFilterModeOn ? 80.0 : 0.0),
                            child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(30),
                                  color: Color.fromRGBO(43, 54, 65, 1),
                                ),
                                child: Wrap(children: [
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Visibility(
                                          visible: !isFilterModeOn && !isRotatingMode,
                                          child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                                            IconButton(
                                              icon: Icon(
                                                Icons.filter,
                                                color: Colors.white,
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  isFilterModeOn = !isFilterModeOn;
                                                });
                                              },
                                            ),
                                            IconButton(
                                              icon: Icon(
                                                Icons.crop,
                                                color: Colors.white,
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  _cropImage();
                                                });
                                              },
                                            ),
                                            if (Platform.isAndroid)
                                              IconButton(
                                                icon: Icon(
                                                  Icons.crop_rotate,
                                                  color: Colors.white,
                                                ),
                                                onPressed: () {
                                                  setState(() => isRotatingMode = !isRotatingMode);
                                                },
                                              ),
                                          ])),
                                      if (isFilterModeOn || isRotatingMode)
                                        Column(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            IconButton(
                                              icon: Icon(
                                                Icons.check,
                                                color: Colors.green,
                                              ),
                                              onPressed: () async {
                                                debugPrint("Клик на зелёную кнопку");
                                                if (isFilterModeOn) {
                                                  await saveImageWithFiltersFromWidget();
                                                } else if (isRotatingMode) {
                                                  //сохранить вращение
                                                  setState(() => isLoading = true);
                                                  String newFilePath = await PhotoUtility.rotateImage(
                                                      widget._cubit.files[currentIndexOfFile].localPath, angleOfRotating);
                                                  debugPrint("Rotating index of current image:$currentIndexOfFile");
                                                  setState(() {
                                                    overrideImage(newFilePath);
                                                    isRotatingMode = false;
                                                    angleOfRotating = 0;
                                                    isLoading = false;
                                                  });
                                                }
                                              },
                                            ),
                                            IconButton(
                                              icon: Icon(
                                                Icons.cancel,
                                                color: Colors.red,
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  isFilterModeOn = false;
                                                  isRotatingMode = false;
                                                  angleOfRotating = 0;
                                                });
                                              },
                                            )
                                          ],
                                        ),
                                    ],
                                  )
                                ])))
                        : null,
                    body: Container(
                      color: Colors.black45,
                      child: isFilterModeOn
                          ? Column(children: [
                              Expanded(
                                  child: RepaintBoundary(
                                key: _globalKey,
                                child: ColorFiltered(
                                  colorFilter: ColorFilter.matrix(filters[currentIndexOfFilter]),
                                  child: widgets[currentIndexOfFile],
                                ),
                              )),
                              widgetCorouselOfFilters(widgets),
                            ])
                          : isRotatingMode
                              ? Stack(
                                  children: [
                                    Align(
                                        alignment: Alignment.center,
                                        child: Transform.rotate(
                                          angle: angleOfRotating * (3.1415926535 / 180),
                                          child: widgets[currentIndexOfFile],
                                        )),
                                    Align(
                                        alignment: Alignment.bottomCenter,
                                        child: Padding(
                                            padding: EdgeInsets.only(bottom: 16),
                                            child: Container(
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(30),
                                                  color: Color.fromRGBO(43, 54, 65, 1),
                                                ),
                                                child: Row(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
                                                  IconButton(
                                                      onPressed: () {
                                                        setState(() {
                                                          angleOfRotating = angleOfRotating - 90;
                                                        });
                                                      },
                                                      icon: Icon(
                                                        Icons.rotate_left,
                                                        size: 48,
                                                        color: Colors.white,
                                                      )),
                                                  IconButton(
                                                      onPressed: () {
                                                        setState(() {
                                                          angleOfRotating = angleOfRotating + 90;
                                                        });
                                                      },
                                                      icon: Icon(
                                                        Icons.rotate_right,
                                                        color: Colors.white,
                                                        size: 48,
                                                      )),
                                                ])))),
                                  ],
                                )
                              : Stack(
                                  children: [
                                    PhotoViewGallery.builder(
                                      gaplessPlayback: true,
                                      enableRotation: false,
                                      scrollPhysics: const BouncingScrollPhysics(),
                                      builder: (BuildContext context, int index) {
                                        //debugPrint("Прорисовка, Index of current image:$index");
                                        return PhotoViewGalleryPageOptions.customChild(
                                          child: widgets[currentIndexOfFile],
                                        );
                                      },
                                      itemCount: widgets.length,
                                      loadingBuilder: (context, event) => Center(
                                        child: Container(
                                          width: 20.0,
                                          height: 20.0,
                                          child: CircularProgressIndicator(
                                            value: event == null ? 0 : event.cumulativeBytesLoaded / (event.expectedTotalBytes ?? 1),
                                          ),
                                        ),
                                      ),
                                      backgroundDecoration: const BoxDecoration(
                                        color: Colors.black,
                                      ),
                                      pageController: widget.pageController,
                                      onPageChanged: onPageChanged,
                                    ),
                                    Visibility(
                                        visible: currentIndexOfFile != 0,
                                        child: Positioned(
                                            left: 0,
                                            top: 0,
                                            bottom: 0,
                                            child: Stack(children: [
                                              Center(
                                                  child: CustomPaint(
                                                painter: SemiCirclePainter(startAngle: math.pi / 2, sweepAngle: -math.pi, center: 0),
                                                size: Size(90, 90),
                                              )),
                                              Center(
                                                  child: IconButton(
                                                icon: SvgPicture.asset(IMG.icons.iconArrowLeft, fit: BoxFit.scaleDown),
                                                onPressed: currentIndexOfFile > 0
                                                    ? () {
                                                        onPageChanged(--currentIndexOfFile);
                                                        widget.pageController.animateToPage(
                                                          currentIndexOfFile,
                                                          duration: Duration(milliseconds: 300),
                                                          curve: Curves.easeInOut,
                                                        );
                                                      }
                                                    : null,
                                              ))
                                            ]))),
                                    Visibility(
                                        visible: currentIndexOfFile != models.length - 1,
                                        child: Positioned(
                                            right: 0,
                                            top: 0,
                                            bottom: 0,
                                            child: Stack(children: [
                                              Center(
                                                  child: CustomPaint(
                                                painter: SemiCirclePainter(startAngle: math.pi / 2, sweepAngle: math.pi, center: 90),
                                                size: Size(90, 90),
                                              )),
                                              Positioned(
                                                  right: 0,
                                                  bottom: 0,
                                                  top: 0,
                                                  child: Center(
                                                    child: IconButton(
                                                      icon: SvgPicture.asset(IMG.icons.iconArrowRight, fit: BoxFit.scaleDown),
                                                      onPressed: currentIndexOfFile < models.length - 1
                                                          ? () {
                                                              onPageChanged(++currentIndexOfFile);
                                                              widget.pageController.animateToPage(
                                                                currentIndexOfFile,
                                                                duration: Duration(milliseconds: 300),
                                                                curve: Curves.easeInOut,
                                                              );
                                                            }
                                                          : null,
                                                    ),
                                                  ))
                                            ])))
                                  ],
                                ),
                    ),
                  ),
                  if (isLoading)
                    Container(
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height,
                      color: Colors.black.withOpacity(0.5),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    )
                ],
              );
            }));
  }
}

class ChewieDemo extends StatefulWidget {
  final FileModel file;

  ChewieDemo({required this.file});

  @override
  State<StatefulWidget> createState() {
    return _ChewieDemoState(file: file);
  }
}

class _ChewieDemoState extends State<ChewieDemo> {
  VideoPlayerController? _controller;
  ChewieController? _chewieController;
  FileModel file;

  _ChewieDemoState({required this.file});

  @override
  void initState() {
    super.initState();
    initializePlayer();
  }

  @override
  void dispose() {
    _controller?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  Future<void> initializePlayer() async {
    _controller = VideoPlayerController.file(File(file.localPath));

    await _controller?.initialize();

    _chewieController = ChewieController(
      videoPlayerController: _controller!,
      aspectRatio: _controller?.value.aspectRatio,
      autoPlay: true,
      looping: false,
      placeholder: Center(
        child: Container(
          height: 40,
          width: 40,
          child: DefaultIndicator,
        ),
      ),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: _chewieController != null && _chewieController!.videoPlayerController.value.isInitialized
            ? Chewie(
                controller: _chewieController!,
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text('Loading'),
                ],
              ),
      ),
    );
  }
}

