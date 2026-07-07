import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:psn.hotels.hub/presentation/blocks/content/content_cubit.dart';
import 'package:psn.hotels.hub/infrastructure/file_utility.dart';
import 'package:psn.hotels.hub/infrastructure/images.gen.dart';
import 'package:psn.hotels.hub/di/service_container.dart';
import 'package:psn.hotels.hub/presentation/items/filters.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:psn.hotels.hub/presentation/ui_helper.dart';
import 'package:psn.hotels.hub/data/models/response_models/file_model_response.dart';
import 'package:psn.hotels.hub/infrastructure/media_editor_helper.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:math' as math;
import '../../../../presentation/blocks/content/states/content_state.dart';
import 'widgets/semi_circle.dart';
import 'widgets/filter_carousel.dart';
import 'widgets/media_item_builder.dart';

class FullMediaPreviewSlider extends StatefulWidget {
  final ContentCubit cubit;
  final int initialPage;
  final PageController pageController;

  FullMediaPreviewSlider(this.cubit, this.initialPage, this.pageController,
      {Key? key});

  @override
  _FullMediaPreviewSliderState createState() => _FullMediaPreviewSliderState();
}

class _FullMediaPreviewSliderState extends State<FullMediaPreviewSlider> {
  int currentIndexOfFile = 0;

  List<List<double>> filters = [
    NO_MATRIX,
    SEPIA_MATRIX,
    GREYSCALE_MATRIX,
    VINTAGE_MATRIX,
    SWEET_MATRIX
  ];

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

  void _saveAndStayOnPage(String newFilePath, ContentState state) {
    final file = state.visibleFiles[currentIndexOfFile];

    final updated = file.copyWith(
      oldLocalPaths: {...file.oldLocalPaths, file.localPath},
      localPath: newFilePath,
      synced: false,
      isEdited: true,
    );

    widget.cubit.updateFile(updated);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.pageController.jumpToPage(currentIndexOfFile);
    });
  }

  final GlobalKey _globalKey = GlobalKey();

  Future<void> _saveImageWithFiltersFromWidget(ContentState state) async {
    setState(() => isLoading = true);

    try {
      final uint8list =
          await MediaEditorHelper.captureWidgetToBytes(_globalKey, pixelRatio);
      final newFilePath = MediaEditorHelper.generateNewPath(
          state.visibleFiles[currentIndexOfFile].localPath);

      await File(newFilePath).writeAsBytes(uint8list);
      _saveAndStayOnPage(newFilePath, state);
    } catch (e) {
      debugPrint("Error saving filtered image: $e");
    }

    setState(() {
      isFilterModeOn = false;
      currentIndexOfFilter = 0;
      isLoading = false;
    });
  }

  Future<void> _cropImage(ContentState state) async {
    final sourcePath = state.visibleFiles[currentIndexOfFile].localPath;
    final croppedPath = await MediaEditorHelper.cropImage(sourcePath);

    if (croppedPath != null) {
      if (Platform.isAndroid) {
        _saveAndStayOnPage(croppedPath, state);
      } else if (Platform.isIOS) {
        final newPath = await FileUtility.moveFile(
          File(croppedPath),
          sourcePath.substring(0, sourcePath.lastIndexOf('/')),
        );
        _saveAndStayOnPage(newPath, state);
      }
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.pageController.jumpToPage(currentIndexOfFile);
      });
    }
  }

  Future<void> _deleteCurrentFile(ContentState state) async {
    Navigator.pop(context, false);
    await widget.cubit.deleteFile(state.visibleFiles[currentIndexOfFile]);
    currentIndexOfFile--;
    if (currentIndexOfFile == -1) {
      currentIndexOfFile = 0;
    }
    if (state.visibleFiles.length == 0) {
      //widget.setStateCallback();
      Navigator.pop(context);
      return;
    }

    setState(() {
      if (currentIndexOfFile >= state.visibleFiles.length) {
        currentIndexOfFile = state.visibleFiles.length - 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: true,
        onPopInvokedWithResult: (didPop, result) {
          // предотвращаем повторный pop
          if (didPop) return;
          Future.microtask(() async {
            // проверка, что экран еще "жив"
            if (!mounted) return false;
            //widget.setStateCallback();
            return Future.value(true);
          });
        },
        child: BlocConsumer<ContentCubit, ContentState>(
            bloc: widget.cubit,
            listener: (context, state) {
              if (state.visibleFiles.isEmpty) {
                Navigator.of(context).pop();
              }
            },
            builder: (context, state) {
              final files = state.visibleFiles;
              debugPrint(
                  "builder state.visibleFiles.length:${state.visibleFiles.length}");
              if (files.isEmpty) {
                return const Scaffold(backgroundColor: Colors.black);
              }
              if (currentIndexOfFile >= files.length) {
                currentIndexOfFile = files.isEmpty ? 0 : files.length - 1;
              }

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
                                Navigator.pop(context);
                              },
                              child: Row(
                                children: [
                                  SizedBox(width: 16),
                                  SvgPicture.asset(IMG.icons.iconArrowBack,
                                      colorFilter: ColorFilter.mode(
                                          Colors.white, BlendMode.srcIn),
                                      fit: BoxFit.scaleDown),
                                ],
                              ),
                            ),
                            title: Text(
                                "${currentIndexOfFile + 1}/${state.visibleFiles.length}",
                                style:
                                    textStyle(color: Colors.white, size: 18)),
                            actions: [
                              IconButton(
                                icon: SvgPicture.asset(IMG.icons.iconDelete,
                                    width: 23,
                                    height: 26,
                                    colorFilter: ColorFilter.mode(
                                        Colors.white, BlendMode.srcIn),
                                    fit: BoxFit.scaleDown),
                                onPressed: () async {
                                  showDialog(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                          title: Text(
                                            "Удалить медиафайл?",
                                            style: textStyle(
                                                size: 18,
                                                weight: FontWeight.w300,
                                                color:
                                                    ColorTextBlackAlertDialog),
                                          ),
                                          surfaceTintColor: Colors.white,
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                              },
                                              child: Text("Нет",
                                                  style: textStyle(
                                                      size: 18,
                                                      weight: FontWeight.w400,
                                                      color:
                                                          ColorTextBlackAlertDialog)),
                                            ),
                                            TextButton(
                                              onPressed: () async {
                                                await _deleteCurrentFile(state);
                                              },
                                              child: Text("Да",
                                                  style: textStyle(
                                                      size: 18,
                                                      weight: FontWeight.w400,
                                                      color: ColorTextOrange)),
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
                                  colorFilter: ColorFilter.mode(
                                      Colors.white, BlendMode.srcIn),
                                ),
                                onPressed: () {
                                  SharePlus.instance.share(ShareParams(files: [
                                    XFile(state.visibleFiles[currentIndexOfFile]
                                        .localPath)
                                  ]));
                                },
                              ),
                              state.visibleFiles[currentIndexOfFile].type ==
                                      FileModelType.Image
                                  ? PopupMenuButton(
                                      iconColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(10))),
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
                                              Text(
                                                  "Сделать главной фото в локации")
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
                                                    "Сделать фото главным в локации ${state.location.name}?",
                                                    style: textStyle(
                                                        size: 18,
                                                        weight: FontWeight.w300,
                                                        color:
                                                            ColorTextBlackAlertDialog),
                                                  ),
                                                  surfaceTintColor:
                                                      Colors.white,
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.pop(context);
                                                      },
                                                      child: Text("Отменить",
                                                          style: textStyle(
                                                              size: 18,
                                                              weight: FontWeight
                                                                  .w400,
                                                              color:
                                                                  ColorTextBlackAlertDialog)),
                                                    ),
                                                    TextButton(
                                                      onPressed: () async {
                                                        widget.cubit
                                                            .setProfileImageOfLocation(
                                                                state.visibleFiles[
                                                                    currentIndexOfFile]);
                                                        Navigator.pop(context);
                                                      },
                                                      child: Text("Да",
                                                          style: textStyle(
                                                              size: 18,
                                                              weight: FontWeight
                                                                  .w400,
                                                              color:
                                                                  ColorTextOrange)),
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
                                                    "Сделать фото главным в отеле ${state.myHotel.name}?",
                                                    style: textStyle(
                                                        size: 18,
                                                        weight: FontWeight.w300,
                                                        color:
                                                            ColorTextBlackAlertDialog),
                                                  ),
                                                  surfaceTintColor:
                                                      Colors.white,
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.pop(context);
                                                      },
                                                      child: Text("Отменить",
                                                          style: textStyle(
                                                              size: 18,
                                                              weight: FontWeight
                                                                  .w400,
                                                              color:
                                                                  ColorTextBlackAlertDialog)),
                                                    ),
                                                    TextButton(
                                                      onPressed: () async {
                                                        widget.cubit
                                                            .setProfileImageOfMyHotel(
                                                                state.visibleFiles[
                                                                    currentIndexOfFile]);
                                                        Navigator.pop(context);
                                                      },
                                                      child: Text("Да",
                                                          style: textStyle(
                                                              size: 18,
                                                              weight: FontWeight
                                                                  .w400,
                                                              color:
                                                                  ColorTextOrange)),
                                                    )
                                                  ]);
                                            },
                                          );
                                        }
                                      },
                                    )
                                  : SizedBox()
                            ],
                          )
                        : null,
                    floatingActionButton: state
                                .visibleFiles[currentIndexOfFile].type ==
                            FileModelType.Image
                        ? Padding(
                            padding: EdgeInsets.only(
                                bottom: isFilterModeOn ? 80.0 : 0.0),
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
                                          visible: !isFilterModeOn &&
                                              !isRotatingMode,
                                          child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                IconButton(
                                                  icon: Icon(
                                                    Icons.filter,
                                                    color: Colors.white,
                                                  ),
                                                  onPressed: () {
                                                    setState(() {
                                                      isFilterModeOn =
                                                          !isFilterModeOn;
                                                    });
                                                  },
                                                ),
                                                IconButton(
                                                  icon: Icon(
                                                    Icons.crop,
                                                    color: Colors.white,
                                                  ),
                                                  onPressed: () {
                                                    _cropImage(state);
                                                  },
                                                ),
                                                if (Platform.isAndroid)
                                                  IconButton(
                                                    icon: Icon(
                                                      Icons.crop_rotate,
                                                      color: Colors.white,
                                                    ),
                                                    onPressed: () {
                                                      setState(() =>
                                                          isRotatingMode =
                                                              !isRotatingMode);
                                                    },
                                                  ),
                                              ])),
                                      if (isFilterModeOn || isRotatingMode)
                                        Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            IconButton(
                                              icon: Icon(
                                                Icons.check,
                                                color: Colors.green,
                                              ),
                                              onPressed: () async {
                                                if (isFilterModeOn) {
                                                  await _saveImageWithFiltersFromWidget(
                                                      state);
                                                } else if (isRotatingMode) {
                                                  setState(
                                                      () => isLoading = true);

                                                  final sourcePath = state
                                                      .visibleFiles[
                                                          currentIndexOfFile]
                                                      .localPath;
                                                  final newFilePath =
                                                      MediaEditorHelper
                                                          .generateNewPath(
                                                              sourcePath);

                                                  final rotatedXFile =
                                                      await MediaEditorHelper
                                                          .rotateImage(
                                                    sourcePath: sourcePath,
                                                    targetPath: newFilePath,
                                                    angle:
                                                        angleOfRotating.toInt(),
                                                  );

                                                  _saveAndStayOnPage(
                                                      rotatedXFile?.path ??
                                                          newFilePath,
                                                      state);

                                                  setState(() {
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
                                                WidgetsBinding.instance
                                                    .addPostFrameCallback((_) {
                                                  if (!mounted) return;
                                                  widget.pageController
                                                      .jumpToPage(
                                                          currentIndexOfFile);
                                                });
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
                                  colorFilter: ColorFilter.matrix(
                                      filters[currentIndexOfFilter]),
                                  child: buildMediaItem(
                                      state.visibleFiles[currentIndexOfFile]),
                                ),
                              )),
                              FilterCarousel(
                                filters: filters,
                                currentFile:
                                    state.visibleFiles[currentIndexOfFile],
                                currentIndexOfFilter: currentIndexOfFilter,
                                onFilterSelected: (index) {
                                  setState(() {
                                    currentIndexOfFilter = index;
                                  });
                                },
                              ),
                            ])
                          : isRotatingMode
                              ? Stack(
                                  children: [
                                    Align(
                                        alignment: Alignment.center,
                                        child: RotatedBox(
                                          quarterTurns: angleOfRotating ~/
                                              90, // 90° = 1, 180° = 2, 270° = 3
                                          child: buildMediaItem(
                                              state.visibleFiles[
                                                  currentIndexOfFile]),
                                        )),
                                    Align(
                                        alignment: Alignment.bottomCenter,
                                        child: Padding(
                                            padding:
                                                EdgeInsets.only(bottom: 16),
                                            child: Container(
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(30),
                                                  color: Color.fromRGBO(
                                                      43, 54, 65, 1),
                                                ),
                                                child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      IconButton(
                                                          onPressed: () {
                                                            setState(() {
                                                              angleOfRotating =
                                                                  angleOfRotating -
                                                                      90;
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
                                                              angleOfRotating =
                                                                  angleOfRotating +
                                                                      90;
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
                                      scrollPhysics:
                                          const BouncingScrollPhysics(),
                                      builder:
                                          (BuildContext context, int index) {
                                        final fileModel = files[index];

                                        final file = File(fileModel.localPath);

                                        final key = ValueKey(
                                          fileModel.localId > 0
                                              ? "id_${fileModel.localId}_${fileModel.localPath}"
                                              : "path_${fileModel.localPath}",
                                        );

                                        if (!file.existsSync()) {
                                          return PhotoViewGalleryPageOptions
                                              .customChild(
                                            child: SizedBox(),
                                          );
                                        }

                                        if (fileModel.type ==
                                            FileModelType.Image) {
                                          return PhotoViewGalleryPageOptions
                                              .customChild(
                                            child: Image.file(file, key: key),
                                          );
                                        } else {
                                          return PhotoViewGalleryPageOptions
                                              .customChild(
                                            child: ChewieDemo(
                                                file: fileModel, key: key),
                                          );
                                        }
                                      },
                                      itemCount: files.length,
                                      loadingBuilder: (context, event) =>
                                          Center(
                                        child: Container(
                                          width: 20.0,
                                          height: 20.0,
                                          child: CircularProgressIndicator(
                                            value: event == null
                                                ? 0
                                                : event.cumulativeBytesLoaded /
                                                    (event.expectedTotalBytes ??
                                                        1),
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
                                                painter: SemiCirclePainter(
                                                    startAngle: math.pi / 2,
                                                    sweepAngle: -math.pi,
                                                    center: 0),
                                                size: Size(90, 90),
                                              )),
                                              Center(
                                                  child: IconButton(
                                                icon: SvgPicture.asset(
                                                    IMG.icons.iconArrowLeft,
                                                    fit: BoxFit.scaleDown),
                                                onPressed: currentIndexOfFile >
                                                        0
                                                    ? () {
                                                        onPageChanged(
                                                            --currentIndexOfFile);
                                                        widget.pageController
                                                            .animateToPage(
                                                          currentIndexOfFile,
                                                          duration: Duration(
                                                              milliseconds:
                                                                  300),
                                                          curve:
                                                              Curves.easeInOut,
                                                        );
                                                      }
                                                    : null,
                                              ))
                                            ]))),
                                    Visibility(
                                        visible: currentIndexOfFile !=
                                            state.visibleFiles.length - 1,
                                        child: Positioned(
                                            right: 0,
                                            top: 0,
                                            bottom: 0,
                                            child: Stack(children: [
                                              Center(
                                                  child: CustomPaint(
                                                painter: SemiCirclePainter(
                                                    startAngle: math.pi / 2,
                                                    sweepAngle: math.pi,
                                                    center: 90),
                                                size: Size(90, 90),
                                              )),
                                              Positioned(
                                                  right: 0,
                                                  bottom: 0,
                                                  top: 0,
                                                  child: Center(
                                                    child: IconButton(
                                                      icon: SvgPicture.asset(
                                                          IMG.icons
                                                              .iconArrowRight,
                                                          fit:
                                                              BoxFit.scaleDown),
                                                      onPressed: currentIndexOfFile <
                                                              state.visibleFiles
                                                                      .length -
                                                                  1
                                                          ? () {
                                                              onPageChanged(
                                                                  ++currentIndexOfFile);
                                                              widget
                                                                  .pageController
                                                                  .animateToPage(
                                                                currentIndexOfFile,
                                                                duration: Duration(
                                                                    milliseconds:
                                                                        300),
                                                                curve: Curves
                                                                    .easeInOut,
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
                      color: applyOpacity(Colors.black, 0.5),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    )
                ],
              );
            }));
  }
}
