import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:psn.hotels.hub/blocks/base_cubit/base_cubit.dart';
import 'package:psn.hotels.hub/blocks/hotel_location/my_hotel_cubit.dart';
import 'package:psn.hotels.hub/blocks/permissions_cubit/permissions_cubit.dart';
import 'package:psn.hotels.hub/helpers/getter_icon_path_category.dart';
import 'package:psn.hotels.hub/helpers/images.gen.dart';
import 'package:psn.hotels.hub/helpers/ui_helper.dart';
import 'package:psn.hotels.hub/models/entities_database/file_model.dart';
import 'package:psn.hotels.hub/models/response_models/file_model_response.dart';
import 'package:psn.hotels.hub/ui/buttons/default_button.dart';
import 'package:psn.hotels.hub/ui/items/default_cupertino_text_field.dart';
import 'package:psn.hotels.hub/ui/items/image_item.dart';
import 'package:psn.hotels.hub/ui/routes/hotel_routes.dart';
import 'package:psn.hotels.hub/ui/screens/base_screen.dart';
import 'package:psn.hotels.hub/ui/screens/my_hotels_flow/camera/custom_camera_screen.dart';
import 'package:psn.hotels.hub/ui/items/permission_denied_dialog.dart';
import 'package:collection/collection.dart';

import 'choose_category_bottom_sheet.dart';

class AddFilesAndInformationScreen extends StatefulWidget {
  final VoidCallback saveCallback;

  AddFilesAndInformationScreen({Key? key, required this.saveCallback}) : super(key: key);

  @override
  _AddFilesAndInformationScreenState createState() => _AddFilesAndInformationScreenState();
}

class _AddFilesAndInformationScreenState extends State<AddFilesAndInformationScreen> {
  StreamSubscription? subscriptionSinc;
  late bool isSyncing;

  Future<void>? futureGetAll; // because TextField doesnt work correctly in FutureBuilder

  List<FileModel> initialFiles = [];
  _AddFilesAndInformationScreenState();
  String currentName = "";
  String currentDescription = "";
  String initialProfilePhotoOfLocation = '';
  String initialProfilePhotoOfMyHotel = '';
  int initialIdCategory = -1;
  ScrollController _scrollController = ScrollController();
  bool _showRequiredFields = false;

  @override
  void initState() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    futureGetAll = getAll();
    currentName = _cubit.locationModel.name;
    currentDescription = _cubit.locationModel.description;
    initialProfilePhotoOfLocation = _cubit.locationModel.pathOfProfilePhoto;
    initialProfilePhotoOfMyHotel = _cubit.myHotelModel.pathOfProfilePhoto;
    initialIdCategory = _cubit.locationModel.idCategory;

    isSyncing = _cubit.services.sinkService.isSyncing;
    subscriptionSinc = _cubit.services.sinkService.isSyncingObserver.stream.listen((item) {
      setState(() {
        isSyncing = item;
      });
    });

    super.initState();
  }

  @override
  void dispose() {
    subscriptionSinc?.cancel();
    currentName = "";
    currentDescription = "";
    super.dispose();
  }

  MyHotelCubit get _cubit {
    return BlocProvider.of<MyHotelCubit>(context);
  }

  PermissionsCubit get _permissionsCubit {
    return BlocProvider.of<PermissionsCubit>(context);
  }

  Function deepEq = const DeepCollectionEquality().equals; //сравнение изначальны файлов и последних файлов в cubit по ссылкам
  bool isExistsEditedFiles() {
    for (var file in _cubit.files) {
      if (file.isEdited) {
        return true;
      }
    }
    return false;
  }

  bool everyModifiedFileWasUploaded() {
    List<FileModel> notSyncedInitialFiles = initialFiles
        .where((file) => file.synced == false)
        .toList(); //функція перевіряє всі файли, і якщо хоча б один змінений файл не синхронізований (file.synced == false), функція повертає false. Інакше, якщо всі змінені файли синхронізовані, функція повертає true.
    // Проходим по каждому несинхронизированному файлу
    for (FileModel notSyncedFile in notSyncedInitialFiles) {
      // Пытаемся найти файл с таким же именем в _cubit.files
      FileModel? modifiedAndNotSyncedFile = _cubit.files.firstWhereOrNull((file) => (file.isEdited == true && file.name == notSyncedFile.name));
      if (modifiedAndNotSyncedFile != null) {
        return false;
      }
    }
    return true;
  }

  // Future<void> deleteteNotSavedFilesFromMemoryOfApplication() async {
  //   List<FileModel> filesThatWillDelete = [];
  //   //deleteting not saved files from memory of application
  //   for (final file in _cubit.files) {
  //     if (!initialFiles.contains(file)) {
  //       filesThatWillDelete.add(file);
  //       FileUtility.deleteFile(file.localPath);
  //     } else if (file.isEdited) {
  //       FileUtility.deleteFile(file.localPath);
  //       file.localPath = file.oldLocalPath;
  //     }
  //   }
  //   _cubit.files.removeWhere((file) => filesThatWillDelete.contains(file));
  // }

  Future<void> save() async {
    // _cubit.files.forEach((file) {
    //   debugPrint("file in save:\nlocal path: ${file.localPath},\nthumb: |${file.thumb}| ");
    // });
    bool wasChanging = false;
    if (!deepEq(initialFiles, _cubit.files) ||
        isExistsEditedFiles() || //сравнение файлов изначальных и окончательных
        currentName != _cubit.locationModel.name || //сравнение текущего имени локации и изначального
        currentDescription != _cubit.locationModel.description || //сравнение текущего описания и изначального
        initialProfilePhotoOfLocation != _cubit.locationModel.pathOfProfilePhoto ||
        initialIdCategory != _cubit.category.id) {
      _cubit.locationModel.name = currentName;
      _cubit.locationModel.description = currentDescription;
      await _cubit.addAndUpdateLocationWithFiles(_cubit.files);
      wasChanging = true;
    } else if (currentName.isEmpty && currentDescription.isEmpty && _cubit.locationModel.name.isEmpty && _cubit.locationModel.description.isEmpty) {
      //для возможности создания пустой локации
      await _cubit.addAndUpdateLocationWithFiles(_cubit.files);
      wasChanging = true;
    }
    if (initialProfilePhotoOfMyHotel != _cubit.myHotelModel.pathOfProfilePhoto) {
      await _cubit.saveProfileImageOfMyHotel();
      wasChanging = true;
    }
    if (wasChanging) {
      debugPrint('NO start sinc after button save');
      _cubit.startSync();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // PopScope doesn't work for ios, so leave it
      onWillPop: () async {
        // widget.saveCallback();
        bool checkingChanging = ((!deepEq(initialFiles, _cubit.files)) ||
            isExistsEditedFiles() || //сравнение файлов изначальных и окончательных
            currentName != _cubit.locationModel.name || //сравнение текущего имени локации и изначального
            currentDescription != _cubit.locationModel.description || //сравнение текущего описания и изначального
            initialProfilePhotoOfMyHotel != _cubit.myHotelModel.pathOfProfilePhoto || //есть ли изменение в профильном фото моего отеля
            initialProfilePhotoOfLocation != _cubit.locationModel.pathOfProfilePhoto ||
            initialIdCategory != _cubit.locationModel.idCategory); //есть ли изменение в профильном фото локации

        debugPrint('Были ли изменения? $checkingChanging');
        debugPrint(' initialIdCategory:$initialIdCategory, _cubit.locationModel.idCategory:${_cubit.locationModel.idCategory}');
        if (checkingChanging) {
          debugPrint('Прошло проверку на изменения');
          bool? result = await showDialog<bool>(
            context: context,
            builder: (context) {
              return AlertDialog(
                  surfaceTintColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  titlePadding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 0),
                  title: Text(
                    "Вы уверены что хотите выйти без сохранения?",
                    style: textStyle(size: 18, weight: FontWeight.w300, color: ColorTextBlackAlertDialog),
                    textAlign: TextAlign.center,
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        // List<FileModel> filesThatWillDelete = [];
                        // //deleteting not saved files from memory of application
                        // for (final file in _cubit.files) {
                        //   if (!initialFiles.contains(file)) {
                        //     filesThatWillDelete.add(file);
                        //     FileUtility.deleteFile(file.localPath);
                        //   } else if (file.isEdited) {
                        //     FileUtility.deleteFile(file.localPath);
                        //     file.localPath = file.oldLocalPath;
                        //   }
                        // }
                        // _cubit.files.removeWhere((file) => filesThatWillDelete.contains(file));

                        //test
                        // await deleteteNotSavedFilesFromMemoryOfApplication();
                        widget.saveCallback();
                        Navigator.pop(context, true);
                      },
                      child: Text("Выйти", style: textStyle(size: 18, weight: FontWeight.w400, color: ColorTextBlackAlertDialog)),
                    ),
                    (isSyncing == true && everyModifiedFileWasUploaded() == false)
                        ? SizedBox()
                        : TextButton(
                            onPressed: () async {
                              await save();
                              // await deleteteNotSavedFilesFromMemoryOfApplication();
                              widget.saveCallback();
                              Navigator.pop(context, true);
                            },
                            child: Text("Cохранить", style: textStyle(size: 18, weight: FontWeight.w400, color: ColorTextOrange)),
                          ),
                  ]);
            },
          );
          if (result == null) {
            result = false;
          }
          return result;
        } else {
          
          // debugPrint('start sinc after button save');
          // ServiceContainer().sinkService.startSinc();
          widget.saveCallback();
          return true;
        }
      },
      child: BlocConsumer(
          bloc: _cubit,
          listener: (context, state) {
            if (state is ErrorState) {
              showSnackBar(context: context, message: state.error ?? "Empty error");
            }
          },
          builder: (context, myHotelState) {
            return BaseScreen(
                state: myHotelState as BaseCubitState,
                child: Scaffold(
                  backgroundColor: ColorWhite,
                  appBar: AppBar(
                    backgroundColor: ColorWhite,
                    surfaceTintColor: Colors.transparent,
                    iconTheme: IconThemeData(color: Colors.black),
                    centerTitle: true,
                    title: Text(_cubit.myHotelModel.name, style: textStyle(weight: Medium5, size: 18)),
                    actions: _cubit.selectedFiles.length > 0
                        ? [
                            IconButton(
                              icon: SvgPicture.asset(IMG.icons.iconDelete,
                                  colorFilter: ColorFilter.mode(Colors.red, BlendMode.srcIn), height: 26, width: 23, fit: BoxFit.scaleDown),
                              onPressed: () {
                                showDialog(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                          title: Text("Удалить выбранные медиафайлы?",
                                              style: textStyle(size: 18, weight: FontWeight.w300, color: ColorTextBlackAlertDialog)),
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
                                                await _cubit.deleteSelectedFiles();
                                                Navigator.pop(context);
                                              },
                                              child: Text("Да", style: textStyle(size: 18, weight: FontWeight.w400, color: ColorTextOrange)),
                                            )
                                          ]);
                                    });
                              },
                            ),
                            IconButton(
                              icon: SvgPicture.asset(
                                IMG.icons.iconShare,
                              ),
                              onPressed: () async {
                                await _cubit.shareSelectedFiles();
                                setState(() {});
                              },
                            ),
                          ]
                        : [],
                    systemOverlayStyle: SystemUiOverlayStyle.dark,
                  ),
                  floatingActionButton: Padding(
                      padding: EdgeInsets.only(bottom: 68, right: 8),
                      child: Container(
                          width: 66,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(19),
                            color: Color.fromRGBO(43, 54, 65, 0.7),
                          ),
                          child: Wrap(children: [
                            Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                              SizedBox(height: 8),
                              IconButton(
                                icon: SvgPicture.asset(IMG.icons.iconCamera, fit: BoxFit.scaleDown),
                                onPressed: () async {
                                  var status = await _permissionsCubit.checkPermissionsForCamera();
                                  if (status == MyPermissionStatus.Granted) {
                                    try {
                                      final cameras = await availableCameras();
                                      Navigator.of(context)
                                          .push(
                                        MaterialPageRoute(
                                          builder: (context) => CustomCameraScreen(cameras: cameras),
                                        ),
                                      )
                                          .then((result) {
                                        if (result != null) {
                                          List<FileModel> filesFromCamera = result;
                                          setState(() {
                                            _cubit.files = [...filesFromCamera.reversed, ..._cubit.files];
                                          });
                                        }
                                      });
                                    } catch (e) {
                                      showSnackBar(context: context, message: e.toString());
                                    }
                                  } else {
                                    showDialog(
                                      context: context,
                                      builder: (context) {
                                        return PermissionDeniedDialog(
                                          target: 'camera',
                                        );
                                      },
                                    );
                                  }
                                },
                              ),
                              Padding(padding: EdgeInsets.symmetric(horizontal: 9), child: Divider(color: Colors.white)),
                              IconButton(
                                icon: SvgPicture.asset(IMG.icons.iconGallery, fit: BoxFit.scaleDown),
                                onPressed: () async {
                                  var status = await _permissionsCubit.checkPermissionsForGallery();
                                  if (status == MyPermissionStatus.Granted) {
                                    await _cubit.addFilesFromGallery();
                                  } else {
                                    showDialog(
                                      context: context,
                                      builder: (context) {
                                        return PermissionDeniedDialog(target: 'gallery');
                                      },
                                    );
                                  }
                                },
                              ),
                              SizedBox(height: 8)
                            ])
                          ]))),
                  body: BlocBuilder(
                    bloc: _permissionsCubit,
                    builder: (context, state) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: LayoutBuilder(
                          builder: (context, constraint) {
                            return SingleChildScrollView(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(minHeight: constraint.maxHeight),
                                child: IntrinsicHeight(
                                  child: _buildBody(),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ));
          }),
    );
  }

  Future<void> getAll() async {
    _cubit.files.clear();
    initialFiles.clear();
    List<FileModel> filesByLocationId = (await _cubit.findFilesByLocationId());
    _cubit.files.addAll(filesByLocationId);
    initialFiles.addAll(filesByLocationId);
    await _cubit.getAllCategories();
    _cubit.category = await _cubit.findCategoryById(_cubit.locationModel.idCategory);
    debugPrint('_cubit.category: ${_cubit.category.description}');
  }

  _buildBody() {
    var width = MediaQuery.of(context).size.width - 24 - 32;
    var oneItemWidth = width / 3;
    var gridHeight = oneItemWidth - (oneItemWidth - (oneItemWidth / 1.05));
    return FutureBuilder(
        future: futureGetAll,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error occurred: ${snapshot.error}"));
          } else {
            List<FileModel> notDeletedFiles = _cubit.files.where((file) => !file.deleted).toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 24),
                Container(
                  height: (_cubit.files.length == 0)
                      ? 0
                      : (_cubit.files.length < 4)
                          ? gridHeight
                          : gridHeight * 2,
                  child: RawScrollbar(
                    thumbColor: const Color.fromARGB(255, 248, 166, 166),
                    radius: Radius.circular(8),
                    thumbVisibility: _cubit.files.length > 5 ? true : false,
                    controller: _scrollController,
                    child: GridView.builder(
                      controller: _scrollController,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 1.1 / 1,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: notDeletedFiles.length,
                      itemBuilder: (BuildContext ctx, index) {
                        return _buildItem(index, notDeletedFiles[index]);
                      },
                    ),
                  ),
                ),
                SizedBox(height: _cubit.files.length == 0 ? 0 : 25),
                GestureDetector(
                    onTap: () {
                      _showCategoriesBottomSheet();
                    },
                    child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _showRequiredFields == true ? Colors.red : ColorBorderV2, // Replace with your border color
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            SvgPicture.asset(_cubit.category.id == -1 ? IMG.icons.iconMapChooseCategory : getIconPathCategoty(_cubit.category.id),
                                fit: BoxFit.scaleDown),
                            SizedBox(width: 9),
                            Expanded(
                                child: Text(
                              _cubit.category.description,
                              style: textStyle(color: (_showRequiredFields == true && _cubit.category.id == -1 )? Color.fromRGBO(160, 160, 160, 1) : Colors.black, size: 14),
                            )),
                            SvgPicture.asset(IMG.icons.iconTriangleDown, fit: BoxFit.scaleDown),
                          ],
                        ))),
                _showRequiredFields == true
                    ? Text('*Это поле является обязательным для заполнения', style: textStyle(color: Colors.red, size: 10))
                    : SizedBox(),
                SizedBox(height: 26),
                Container(
                  height: 66,
                  child: DefaultTextField(
                    initialText: currentName,
                    onChanged: (newValue) {
                      currentName = newValue;
                    },
                    maxLenght: 256,
                    placeholder: "Название локации",
                  ),
                ),
                SizedBox(height: 26),
                Expanded(
                  child: Scrollbar(
                    child: DefaultTextField(
                      initialText: currentDescription,
                      onChanged: (newValue) {
                        currentDescription = newValue;
                      },
                      // multiline: true,
                      maxLines: 10,
                      minLines: 4,
                      maxLenght: 1000,
                      placeholder: "Описание",
                      alignLabelWithHint: true,
                    ),
                  ),
                ),
                // Spacer(),
                SizedBox(height: 20),
                SafeArea(
                    top: true,
                    //bottom: true,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 20),
                      child: DefaultButton(
                        title: "Сохранить",
                        loading: (isSyncing == true && everyModifiedFileWasUploaded() == false),
                        enable: !((isSyncing == true && everyModifiedFileWasUploaded() == false)),
                        height: 55,
                        textSize: 18,
                        scheme: DefaultButtonScheme.Orange,
                        onPressed: () async {
                          if (_cubit.category.id == -1) {
                            setState(() => _showRequiredFields = true);
                          } else {
                            _showRequiredFields=false;
                            await save();
                            widget.saveCallback();
                            Navigator.pop(context);
                          }
                        },
                      ),
                    )),
              ],
            );
          }
        });
  }

  static const double borderRadiusOfImage = 8;
  Widget _buildItem(int index, FileModel model) {
    //var model = _cubit.files.toList()[index];
    return InkWell(
      // highlightColor: Colors.white,
      // splashColor: Colors.white,
      onTap: () {
        if (_cubit.selectedFiles.isEmpty) {
          var file = File(model.localPath);
          if (file.existsSync()) {
            showFullMediaPreviewSlider(context, _cubit, () {
              setState(() {});
            }, index);
          }
        } else {
          setState(() {
            _cubit.selectFile(model);
          });
        }
      },
      onLongPress: () {
        setState(() {
          _cubit.selectFile(model);
        });
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadiusOfImage),
        child: Stack(
          alignment: AlignmentDirectional.center,
          children: [
            Container(
              width: 114,
              height: 106,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadiusOfImage + 4),
                color: Color.fromRGBO(255, 255, 255, 0.5),
                border: _cubit.fileSelected(model)
                    ? Border.all(
                        color: ColorOrange,
                        width: 2,
                      )
                    : null,
              ),
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(borderRadiusOfImage),
                  child: model.type == FileModelType.Video
                      ? ((File(model.localPath).existsSync()) // проверка существования видео
                          ? ImageItem(imagePath: model.thumb ?? "")
                          : ImageItem(imagePath: model.localPath))
                      : ImageItem(imagePath: model.localPath)),
            ),
            if (model.type == FileModelType.Video)
              Positioned.fill(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: SvgPicture.asset(
                      IMG.icons.playPNG,
                      fit: BoxFit.scaleDown,
                      colorFilter: ColorFilter.mode(Color.fromARGB(255, 189, 189, 189), BlendMode.srcIn),
                    ),
                  ),
                ),
              ),
            Positioned(
                left: 4,
                top: 6,
                child: Row(children: [
                  model.localPath == _cubit.locationModel.pathOfProfilePhoto
                      ? SvgPicture.asset(IMG.icons.iconProfilePhotoOfLocation, fit: BoxFit.scaleDown)
                      : SizedBox(),
                  SizedBox(width: model.localPath == _cubit.locationModel.pathOfProfilePhoto ? 4 : 0),
                  model.localPath == _cubit.myHotelModel.pathOfProfilePhoto
                      ? SvgPicture.asset(IMG.icons.iconProfilePhotoOfMyHotel, fit: BoxFit.scaleDown)
                      : SizedBox()
                ])),
            if (model.synced == true)
              Positioned(right: 4, top: 4, child: SvgPicture.asset(IMG.icons.downloadComplite, width: 30, height: 30, fit: BoxFit.scaleDown))
            else if (model.syncError == true)
              Positioned(right: 7, top: 6, child: SvgPicture.asset(IMG.icons.downloadFailed, width: 24, height: 24, fit: BoxFit.scaleDown))
            else if (model.synced == false)
              Positioned(
                right: 4,
                top: 4,
                child: SvgPicture.asset(IMG.icons.uploading, width: 30, height: 30, fit: BoxFit.scaleDown),
              ),
            if (_cubit.selectedFiles.isNotEmpty)
              Positioned(
                  left: 4,
                  top: 4,
                  child: _cubit.fileSelected(model)
                      ? Container(
                          width: 25,
                          height: 25,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Color.fromRGBO(255, 255, 255, 1),
                          ),
                          child: SvgPicture.asset(IMG.icons.select, width: 20, height: 20, fit: BoxFit.scaleDown),
                        )
                      : Container(
                          width: 25,
                          height: 25,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Color.fromRGBO(255, 255, 255, 0.5),
                            border: Border.all(
                              color: Colors.white, // White color for the border
                              width: 2, // Width of the border
                            ),
                          ),
                        ))
          ],
        ),
      ),
    );
  }

  _showCategoriesBottomSheet() {
    showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        isScrollControlled: true,
        builder: (BuildContext bc) {
          return Container(
              height: MediaQuery.of(context).size.height * 0.9,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32.0),
                  topRight: Radius.circular(32.0),
                ),
                color: Colors.white,
              ),
              child: CategoriesBottomSheet(
                categories: _cubit.categories,
                onTapCallback: (selectedCategory) async {
                  _cubit.category = await _cubit.findCategoryById(selectedCategory!.id);
                  setState(() {
                    _cubit.locationModel.idCategory = selectedCategory.id;
                  });
                },
              ));
        });
  }
}
