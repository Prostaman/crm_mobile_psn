import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:psn.hotels.hub/presentation/blocks/content/content_cubit.dart';
import 'package:psn.hotels.hub/presentation/blocks/content/states/content_state.dart';
import 'package:psn.hotels.hub/presentation/blocks/permissions_cubit/permissions_cubit.dart';
import 'package:psn.hotels.hub/infrastructure/getter_icon_path_category.dart';
import 'package:psn.hotels.hub/infrastructure/images.gen.dart';
import 'package:psn.hotels.hub/presentation/items/loading_indicator.dart';
import 'package:psn.hotels.hub/presentation/ui_helper.dart';
import 'package:psn.hotels.hub/data/models/entities_database/category_of_location_model.dart';
import 'package:psn.hotels.hub/data/models/entities_database/file_model.dart';
import 'package:psn.hotels.hub/data/models/response_models/file_model_response.dart';
import 'package:psn.hotels.hub/presentation/buttons/default_button.dart';
import 'package:psn.hotels.hub/presentation/items/default_cupertino_text_field.dart';
import 'package:psn.hotels.hub/presentation/items/image_item.dart';
import 'package:psn.hotels.hub/presentation/routes/hotel_routes.dart';
import 'package:psn.hotels.hub/presentation/screens/my_hotels_flow/camera/custom_camera_screen.dart';
import 'package:psn.hotels.hub/presentation/items/permission_denied_dialog.dart';
import 'choose_category_bottom_sheet.dart';

class ContentScreen extends StatefulWidget {
  final VoidCallback saveCallback;

  ContentScreen({Key? key, required this.saveCallback}) : super(key: key);

  @override
  _ContentScreenState createState() => _ContentScreenState();
}

class _ContentScreenState extends State<ContentScreen> {
  late final ContentCubit _cubit;
  late final PermissionsCubit _permissionsCubit;
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;

  ScrollController _scrollController = ScrollController();
  bool _showRequiredFields = false;

  @override
  void initState() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.initState();
    _cubit = BlocProvider.of<ContentCubit>(context);
    _permissionsCubit = BlocProvider.of<PermissionsCubit>(context);
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext contextWidget) {
    return BlocConsumer<ContentCubit, ContentState>(
      bloc: _cubit,
      listener: (context, state) {
        if (state.error != null) {
          showSnackBar(context: context, message: state.error ?? "Empty error");
        }
        _nameController.text = state.location.name;
        _descriptionController.text = state.location.description;
      },
      builder: (context, state) {
        return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) {
              if (didPop) return;
              _handlePop(state);
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

  void _handlePop(ContentState state) async {
    if (state.location.localId == -1 ||
        _cubit.hasChanges(
            currentName: _nameController.text,
            currentDescription: _descriptionController.text)) {
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
                    //widget.saveCallback();
                    _cubit.resetInitialState();
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
                    if (state.category.id == -1) {
                      setState(() => _showRequiredFields = true);
                      Navigator.pop(contextAlertDialog, false);
                    } else {
                      await _cubit.save(
                        currentName: _nameController.text,
                        currentDescription: _descriptionController.text,
                      );
                      widget.saveCallback();
                      Navigator.pop(contextAlertDialog, true);
                    }
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
      _cubit.resetInitialState();
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

  void _showAddMediaOptions() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            color: ColorWhite,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                  _openCamera();
                },
                child: SvgPicture.asset(
                  IMG.icons.iconCamera,
                  width: 80,
                  height: 80,
                  fit: BoxFit.contain,
                  colorFilter:
                      const ColorFilter.mode(ColorOrange, BlendMode.srcIn),
                ),
              ),
              Container(width: 2, height: 100, color: ColorBorderV2),
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                  _openGallery();
                },
                child: SvgPicture.asset(
                  IMG.icons.iconGallery,
                  width: 80,
                  height: 80,
                  fit: BoxFit.contain,
                  colorFilter:
                      const ColorFilter.mode(ColorOrange, BlendMode.srcIn),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openCamera() async {
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
  }

  Future<void> _openGallery() async {
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
  }

  Widget _buildAddGridItem() {
    return InkWell(
      onTap: () => _showAddMediaOptions(),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: const Color.fromRGBO(245, 245, 245, 1),
          border: Border.all(color: ColorBorderV2),
        ),
        child: const Center(
          child: Icon(
            Icons.add,
            color: ColorOrange,
            size: 32,
          ),
        ),
      ),
    );
  }

  _buildBody(ContentState state) {
    var width = MediaQuery.of(context).size.width - 24 - 32;
    var oneItemWidth = width / 3;
    var gridHeight = oneItemWidth - (oneItemWidth - (oneItemWidth / 1.05));

    List<FileModel> notDeletedFiles = state.visibleFiles;
    int totalItems = notDeletedFiles.length + 1;
    int displayCount = ((totalItems + 2) ~/ 3) * 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        Container(
          height: (displayCount <= 3) ? gridHeight : gridHeight * 2,
          child: RawScrollbar(
            thumbColor: const Color.fromARGB(255, 248, 166, 166),
            radius: const Radius.circular(8),
            thumbVisibility: totalItems > 6 ? true : false,
            controller: _scrollController,
            child: GridView.builder(
              controller: _scrollController,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.1 / 1,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: displayCount,
              itemBuilder: (BuildContext ctx, index) {
                if (index == 0) {
                  return _buildAddGridItem();
                }
                if (index < totalItems) {
                  return _buildItem(index - 1, state, notDeletedFiles);
                }
                return _buildEmptySlot();
              },
            ),
          ),
        ),
        const SizedBox(height: 25),
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
            controller: _nameController,
            onChanged: (newValue) {},
            maxLenght: 256,
            placeholder: "Название локации",
          ),
        ),
        const SizedBox(height: 26),
        Expanded(
          child: Scrollbar(
            child: DefaultTextField(
              controller: _descriptionController,
              onChanged: (newValue) {},
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
                  debugPrint('state.category.id:${state.category.id}');
                  if (state.category.id == -1) {
                    setState(() => _showRequiredFields = true);
                  } else {
                    _showRequiredFields = false;
                    await _cubit.save(
                        currentName: _nameController.text,
                        currentDescription: _descriptionController.text);
                    widget.saveCallback();
                    if (mounted) Navigator.pop(context);
                  }
                },
              ),
            )),
      ],
    );
  }

  Widget _buildEmptySlot() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: const Color.fromRGBO(245, 245, 245, 1),
        border: Border.all(color: ColorBorderV2),
      ),
    );
  }

  Widget _buildItem(
      int index, ContentState state, List<FileModel> notDeletedFiles) {
    const double borderRadiusOfImage = 8;
    final model = notDeletedFiles[index];
    return InkWell(
        key: ValueKey(model.localId),
        onTap: () {
          if (state.selectedIds.isEmpty) {
            var file = File(model.localPath);
            if (file.existsSync()) {
              showFullMediaPreviewSlider(context, _cubit, index);
            }
          } else {
            _cubit.selectFile(model);
          }
        },
        onLongPress: () {
          _cubit.selectFile(model);
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadiusOfImage),
            color: const Color.fromRGBO(245, 245, 245, 1),
          ),
          foregroundDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadiusOfImage),
            border: Border.all(
              color: _cubit.fileSelected(model) ? ColorOrange : ColorBorderV2,
              width: _cubit.fileSelected(model) ? 3 : 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadiusOfImage),
            child: Stack(
              alignment: AlignmentDirectional.center,
              children: [
                Positioned.fill(
                  child: model.type == FileModelType.Video
                      ? ((File(model.localPath).existsSync())
                          ? ImageItem(imagePath: model.thumb ?? "")
                          : ImageItem(imagePath: model.localPath))
                      : ImageItem(imagePath: model.localPath),
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
                              Color.fromARGB(255, 189, 189, 189),
                              BlendMode.srcIn),
                        ),
                      ),
                    ),
                  ),
                Positioned(
                    left: 4,
                    top: 6,
                    child: Row(children: [
                      state.location.pathOfProfilePhoto == model.localPath
                          ? SvgPicture.asset(
                              IMG.icons.iconProfilePhotoOfLocation,
                              fit: BoxFit.scaleDown)
                          : const SizedBox(),
                      SizedBox(
                          width: state.location.pathOfProfilePhoto ==
                                  model.localPath
                              ? 4
                              : 0),
                      state.myHotel.pathOfProfilePhoto == model.localPath
                          ? SvgPicture.asset(
                              IMG.icons.iconProfilePhotoOfMyHotel,
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
                      child: _cubit.fileSelected(model)
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
        ));
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
