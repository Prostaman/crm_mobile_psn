import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:psn.hotels.hub/blocks/base_cubit/base_cubit.dart';
import 'package:psn.hotels.hub/blocks/files/files_cubit.dart';
import 'package:psn.hotels.hub/blocks/files/states/file_state.dart';
import 'package:psn.hotels.hub/blocks/files/states/files_screen_state.dart';
import 'package:psn.hotels.hub/blocks/permissions_cubit/permissions_cubit.dart';
import 'package:psn.hotels.hub/helpers/getter_icon_path_category.dart';
import 'package:psn.hotels.hub/helpers/images.gen.dart';
import 'package:psn.hotels.hub/presentation/items/loading_indicator.dart';
import 'package:psn.hotels.hub/presentation/ui_helper.dart';
import 'package:psn.hotels.hub/models/entities_database/category_of_location_model.dart';
import 'package:psn.hotels.hub/models/entities_database/file_model.dart';
import 'package:psn.hotels.hub/models/entities_database/my_hotel_model.dart';
import 'package:psn.hotels.hub/models/response_models/file_model_response.dart';
import 'package:psn.hotels.hub/presentation/buttons/default_button.dart';
import 'package:psn.hotels.hub/presentation/items/default_cupertino_text_field.dart';
import 'package:psn.hotels.hub/presentation/items/image_item.dart';
import 'package:psn.hotels.hub/presentation/routes/hotel_routes.dart';
import 'package:psn.hotels.hub/presentation/screens/base_screen.dart';
import 'package:psn.hotels.hub/presentation/screens/my_hotels_flow/camera/custom_camera_screen.dart';
import 'package:psn.hotels.hub/presentation/items/permission_denied_dialog.dart';
import 'package:psn.hotels.hub/presentation/ui_helper.dart';
import 'choose_category_bottom_sheet.dart';
import 'extension/files_state_diff.dart';

class AddFilesAndInformationScreen extends StatefulWidget {
  final VoidCallback saveCallback;

  AddFilesAndInformationScreen({Key? key, required this.saveCallback})
      : super(key: key);

  @override
  _AddFilesAndInformationScreenState createState() =>
      _AddFilesAndInformationScreenState();
}

class _AddFilesAndInformationScreenState
    extends State<AddFilesAndInformationScreen> {
  late final FilesCubit _cubit;
  late final PermissionsCubit _permissionsCubit;

  late String currentName;
  late String currentDescription;

  // late final String? initLocationName;
  // late final String? initLocationDescription;
  // late final String? initialProfilePhotoOfLocation;
  // late final String? initialProfilePhotoOfMyHotel;
  // late final int? initialIdCategory;
  // List<FileModel> initialFiles = [];

  late final FilesState _initialState;

  ScrollController _scrollController = ScrollController();
  bool _showRequiredFields = false;

  @override
  void initState() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.initState();
    _cubit = BlocProvider.of<FilesCubit>(context);
    _permissionsCubit = BlocProvider.of<PermissionsCubit>(context);
    // currentName = state.location.name;
    // currentDescription = state.location.description;
    // initLocationName = state.location.name;
    // initLocationDescription = state.location.description;
    // initialProfilePhotoOfLocation = state.location.pathOfProfilePhoto;
    // initialProfilePhotoOfMyHotel = state.myHotel.pathOfProfilePhoto;
    // initialIdCategory = state.location.idCategory;
    // initialFiles = state.files;
    _initialState = context.read<FilesCubit>().state;
  }

  @override
  Widget build(BuildContext contextWidget) {
    return BlocConsumer<FilesCubit, FilesState>(
      bloc: _cubit,
      listener: (context, state) {
        if (state is ErrorState) {
          showSnackBar(context: context, message: state.error ?? "Empty error");
        }
      },
      builder: (context, state) {
        return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) {
              if (didPop) return;
              _handlePop();
            },
            child: Scaffold(
              backgroundColor: ColorWhite,
              appBar: AppBar(
                backgroundColor: ColorWhite,
                surfaceTintColor: Colors.transparent,
                iconTheme: const IconThemeData(color: Colors.black),
                centerTitle: true,
                title: Text(state.myHotel.name,
                    style: textStyle(weight: Medium5, size: 18)),
                actions: state.selectedIds.length > 0
                    ? [
                        IconButton(
                          icon: SvgPicture.asset(IMG.icons.iconDelete,
                              colorFilter: const ColorFilter.mode(
                                  Colors.red, BlendMode.srcIn),
                              height: 26,
                              width: 23,
                              fit: BoxFit.scaleDown),
                          onPressed: () => _showDeleteDialog(),
                        ),
                        IconButton(
                          icon: SvgPicture.asset(IMG.icons.iconShare),
                          onPressed: () async {
                            await _cubit.shareSelectedFiles();
                          },
                        ),
                      ]
                    : [],
                systemOverlayStyle: SystemUiOverlayStyle.dark,
              ),
              floatingActionButton: _buildFAB(),
              body: state.isLoading == false
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: LayoutBuilder(
                        builder: (context, constraint) {
                          return SingleChildScrollView(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                  minHeight: constraint.maxHeight),
                              child: IntrinsicHeight(
                                child: _buildBody(state),
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  : const LoadingIndicatorWidget(),
            ));
      },
    );
  }

  bool get hasChanges =>
      context.read<FilesCubit>().state.isDifferentFrom(_initialState);

  void _handlePop() async {
    if (hasChanges) {
      bool? resultAlertDialog = await showDialog<bool>(
        context: context,
        builder: (contextAlertDialog) {
          return AlertDialog(
              surfaceTintColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              titlePadding: const EdgeInsets.only(
                  left: 20, right: 20, top: 20, bottom: 0),
              title: Text(
                "Вы уверены что хотите выйти без сохранения?",
                style: textStyle(
                    size: 18,
                    weight: FontWeight.w300,
                    color: ColorTextBlackAlertDialog),
                textAlign: TextAlign.center,
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    widget.saveCallback();
                    Navigator.pop(contextAlertDialog, true);
                  },
                  child: Text("Выйти",
                      style: textStyle(
                          size: 18,
                          weight: FontWeight.w400,
                          color: ColorTextBlackAlertDialog)),
                ),
                TextButton(
                  onPressed: () async {
                    await _cubit.save(
                      currentName: currentName,
                      currentDescription: currentDescription,
                    );

                    widget.saveCallback();
                    Navigator.pop(contextAlertDialog, true);
                  },
                  child: Text("Cохранить",
                      style: textStyle(
                          size: 18,
                          weight: FontWeight.w400,
                          color: ColorTextOrange)),
                ),
              ]);
        },
      );
      if (resultAlertDialog == true && mounted) {
        Navigator.of(context).pop();
      }
    } else {
      widget.saveCallback();
      Navigator.of(context).pop();
    }
  }

  void _showDeleteDialog() {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
              title: Text("Удалить выбранные медиафайлы?",
                  style: textStyle(
                      size: 18,
                      weight: FontWeight.w300,
                      color: ColorTextBlackAlertDialog)),
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
                          color: ColorTextBlackAlertDialog)),
                ),
                TextButton(
                  onPressed: () async {
                    await _cubit.deleteSelectedFiles();
                    Navigator.pop(context);
                  },
                  child: Text("Да",
                      style: textStyle(
                          size: 18,
                          weight: FontWeight.w400,
                          color: ColorTextOrange)),
                )
              ]);
        });
  }

  Widget _buildFAB() {
    return Padding(
        padding: const EdgeInsets.only(bottom: 68, right: 8),
        child: Container(
            width: 66,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(19),
              color: const Color.fromRGBO(43, 54, 65, 0.7),
            ),
            child: Wrap(children: [
              Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                const SizedBox(height: 8),
                IconButton(
                  key: const ValueKey('camera_button'),
                  icon: SvgPicture.asset(IMG.icons.iconCamera,
                      fit: BoxFit.scaleDown),
                  onPressed: () async {
                    var status =
                        await _permissionsCubit.checkPermissionsForCamera();
                    if (status == MyPermissionStatus.Granted) {
                      try {
                        final cameras = await availableCameras();
                        Navigator.of(context)
                            .push(
                          MaterialPageRoute(
                            builder: (context) =>
                                CustomCameraScreen(cameras: cameras),
                          ),
                        )
                            .then((result) {
                          if (result != null) {
                            _cubit.setFilesFromCamera(result);
                          }
                        });
                      } catch (e) {
                        showSnackBar(context: context, message: e.toString());
                      }
                    } else {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return PermissionDeniedDialog(target: 'camera');
                        },
                      );
                    }
                  },
                ),
                const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 9),
                    child: Divider(color: Colors.white)),
                IconButton(
                  icon: SvgPicture.asset(IMG.icons.iconGallery,
                      fit: BoxFit.scaleDown),
                  onPressed: () async {
                    var status =
                        await _permissionsCubit.checkPermissionsForGallery();
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
                const SizedBox(height: 8)
              ])
            ])));
  }

  _buildBody(FilesState state) {
    var width = MediaQuery.of(context).size.width - 24 - 32;
    var oneItemWidth = width / 3;
    var gridHeight = oneItemWidth - (oneItemWidth - (oneItemWidth / 1.05));

    List<FileModel> notDeletedFiles = state.notDeletedFiles;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        Container(
          height: (notDeletedFiles.isEmpty)
              ? 0
              : (notDeletedFiles.length < 4)
                  ? gridHeight
                  : gridHeight * 2,
          child: RawScrollbar(
            thumbColor: const Color.fromARGB(255, 248, 166, 166),
            radius: const Radius.circular(8),
            thumbVisibility: notDeletedFiles.length > 5 ? true : false,
            controller: _scrollController,
            child: GridView.builder(
              controller: _scrollController,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.1 / 1,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: notDeletedFiles.length,
              itemBuilder: (BuildContext ctx, index) {
                return _buildItem(index, state, notDeletedFiles);
              },
            ),
          ),
        ),
        SizedBox(height: notDeletedFiles.isEmpty ? 0 : 25),
        GestureDetector(
            onTap: () {
              _showCategoriesBottomSheet(state.categories);
            },
            child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _showRequiredFields == true
                        ? Colors.red
                        : ColorBorderV2,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    SvgPicture.asset(
                        state.category.id == -1
                            ? IMG.icons.iconMapChooseCategory
                            : getIconPathCategoty(state.category.id),
                        fit: BoxFit.scaleDown),
                    const SizedBox(width: 9),
                    Expanded(
                        child: Text(
                      state.category.description,
                      style: textStyle(
                          color: (_showRequiredFields == true &&
                                  state.category.id == -1)
                              ? const Color.fromRGBO(160, 160, 160, 1)
                              : Colors.black,
                          size: 14),
                    )),
                    SvgPicture.asset(IMG.icons.iconTriangleDown,
                        fit: BoxFit.scaleDown),
                  ],
                ))),
        _showRequiredFields == true
            ? Text('*Это поле является обязательным для заполнения',
                style: textStyle(color: Colors.red, size: 10))
            : const SizedBox(),
        const SizedBox(height: 26),
        SizedBox(
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
        const SizedBox(height: 26),
        Expanded(
          child: Scrollbar(
            child: DefaultTextField(
              initialText: currentDescription,
              onChanged: (newValue) {
                currentDescription = newValue;
              },
              maxLines: 10,
              minLines: 4,
              maxLenght: 1000,
              placeholder: "Описание",
              alignLabelWithHint: true,
            ),
          ),
        ),
        const SizedBox(height: 20),
        SafeArea(
            top: true,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: DefaultButton(
                title: "Сохранить",
                height: 55,
                textSize: 18,
                scheme: DefaultButtonScheme.Orange,
                onPressed: () async {
                  if (state.category.id == -1) {
                    setState(() => _showRequiredFields = true);
                  } else {
                    _showRequiredFields = false;
                    await _cubit.save(
                        currentName: currentName,
                        currentDescription: currentDescription);
                    widget.saveCallback();
                    if (mounted) Navigator.pop(context);
                  }
                },
              ),
            )),
      ],
    );
  }

  Widget _buildItem(
      int index, FilesState state, List<FileModel> notDeletedFiles) {
    const double borderRadiusOfImage = 8;
    final model = notDeletedFiles[index];
    return InkWell(
      onTap: () {
        if (state.selectedIds.isEmpty) {
          var file = File(model.localPath);
          if (file.existsSync()) {
            showFullMediaPreviewSlider(context, _cubit, () {
              setState(() {});
            }, index);
          }
        } else {
          _cubit.selectFile(model);
        }
      },
      onLongPress: () {
        _cubit.selectFile(model);
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
                color: const Color.fromRGBO(255, 255, 255, 0.5),
                border: _cubit.fileSelected(model.localId)
                    ? Border.all(
                        color: ColorOrange,
                        width: 2,
                      )
                    : null,
              ),
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(borderRadiusOfImage),
                  child: model.type == FileModelType.Video
                      ? ((File(model.localPath).existsSync())
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
                      colorFilter: const ColorFilter.mode(
                          Color.fromARGB(255, 189, 189, 189), BlendMode.srcIn),
                    ),
                  ),
                ),
              ),
            Positioned(
                left: 4,
                top: 6,
                child: Row(children: [
                  state.location.pathOfProfilePhoto == model.localPath
                      ? SvgPicture.asset(IMG.icons.iconProfilePhotoOfLocation,
                          fit: BoxFit.scaleDown)
                      : const SizedBox(),
                  SizedBox(
                      width:
                          state.location.pathOfProfilePhoto == model.localPath
                              ? 4
                              : 0),
                  state.myHotel.pathOfProfilePhoto == model.localPath
                      ? SvgPicture.asset(IMG.icons.iconProfilePhotoOfMyHotel,
                          fit: BoxFit.scaleDown)
                      : const SizedBox()
                ])),
            if (model.synced == true)
              Positioned(
                  right: 4,
                  top: 4,
                  child: SvgPicture.asset(IMG.icons.downloadComplite,
                      width: 30, height: 30, fit: BoxFit.scaleDown))
            else if (model.syncError == true)
              Positioned(
                  right: 7,
                  top: 6,
                  child: SvgPicture.asset(IMG.icons.downloadFailed,
                      width: 24, height: 24, fit: BoxFit.scaleDown))
            else if (model.synced == false)
              Positioned(
                right: 4,
                top: 4,
                child: SvgPicture.asset(IMG.icons.uploading,
                    width: 30, height: 30, fit: BoxFit.scaleDown),
              ),
            if (state.selectedIds.isNotEmpty)
              Positioned(
                  left: 4,
                  top: 4,
                  child: _cubit.fileSelected(model.localId)
                      ? Container(
                          width: 25,
                          height: 25,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: const Color.fromRGBO(255, 255, 255, 1),
                          ),
                          child: SvgPicture.asset(IMG.icons.select,
                              width: 20, height: 20, fit: BoxFit.scaleDown),
                        )
                      : Container(
                          width: 25,
                          height: 25,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: const Color.fromRGBO(255, 255, 255, 0.5),
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                        ))
          ],
        ),
      ),
    );
  }

  _showCategoriesBottomSheet(List<CategoryModel> categories) {
    showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        isScrollControlled: true,
        builder: (BuildContext bc) {
          return Container(
              height: MediaQuery.of(context).size.height * 0.9,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32.0),
                  topRight: Radius.circular(32.0),
                ),
                color: Colors.white,
              ),
              child: CategoriesBottomSheet(
                categories: categories,
                onTapCallback: (selectedCategory) async {
                  if (selectedCategory != null) {
                    _cubit.setCategory(selectedCategory);
                  }
                },
              ));
        });
  }
}
