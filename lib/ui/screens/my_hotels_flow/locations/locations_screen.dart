import 'dart:async';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:psn.hotels.hub/blocks/edit_hotel/edit_hotel_cubit.dart';
import 'package:psn.hotels.hub/db/db_manager.dart';
import 'package:psn.hotels.hub/helpers/format_date.dart';
import 'package:psn.hotels.hub/helpers/getter_icon_path_category.dart';
import 'package:psn.hotels.hub/helpers/images.gen.dart';
import 'package:psn.hotels.hub/helpers/ui_helper.dart';
import 'package:psn.hotels.hub/models/entities_database/file_model.dart';
import 'package:psn.hotels.hub/models/entities_database/location_model.dart';
import 'package:psn.hotels.hub/services/service_container.dart';
import 'package:psn.hotels.hub/ui/buttons/default_button.dart';
import 'package:psn.hotels.hub/ui/items/indicator_of_uploading.dart';
import 'package:psn.hotels.hub/ui/routes/hotel_routes.dart';
import 'package:psn.hotels.hub/ui/screens/base_screen.dart';
import 'package:collection/collection.dart';
import '../../../../../blocks/base_cubit/base_cubit.dart';
import 'profile_image_of_location_widget.dart';
import 'edit_description_bottom_sheet.dart';

class LocationsScreen extends StatefulWidget {
  final VoidCallback updateCallback;
  LocationsScreen({
    Key? key,
    required this.updateCallback,
  }) : super(key: key);

  @override
  _LocationsScreenState createState() => _LocationsScreenState();
}

class _LocationsScreenState extends State<LocationsScreen> with TickerProviderStateMixin {
  StreamSubscription? subscriptionSinc;
  late DBManager db;
  double percentLoaded = 0;
  List<LocationModel> locations = [];
  List<List<FileModel>?> listOflistOfFiles = [];
  List<double> listOfPercentLoaded = [];
  int allFilesLoadedLenght = 0;
  double percentOfLoadingAllFiles = 0;
  int allFilesLength = 0;
  List<String> descriptionCategories = [];

  Future<void>? futureGetAll; // because after setState make reload of data

  List<SlidableController> controllers = [];

  late ScrollController _scrollController;
  double _scrollPosition = 0;

  @override
  void initState() {
    db = DBManager();
    subscriptionSinc = _cubit.services.sinkService.syncSuccess.stream.listen((item) {
      //_cubit.refresh();
      setState(() {
        _scrollController = ScrollController(initialScrollOffset: _scrollPosition);
      });
    });
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    subscriptionSinc?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> getAll() async {
    locations = (await _cubit.getLocations() ?? []).reversed.toList();
    percentLoaded = await _cubit.getPercentLoadedOfAllFilesOfMyHotel();
    listOflistOfFiles.clear();
    listOfPercentLoaded.clear();
    descriptionCategories.clear();
    allFilesLoadedLenght = 0;
    percentOfLoadingAllFiles = 0;
    allFilesLength = 0;
    for (var location in locations) {
      descriptionCategories.add(await _cubit.findDescriptionOfCategoryById(location.idCategory));
      var files = await _cubit.findFilesByLocationId(location.localId);
      List<FileModel> notDeletedFiles = [];
      files.forEach((file) {
        if (file.deleted == false) {
          notDeletedFiles.add(file);
          allFilesLength++;
          if (file.synced) {
            allFilesLoadedLenght += 1;
          }
        }
      });
      listOflistOfFiles.add(notDeletedFiles);
      var percentOfLoaded = await _cubit.getPercentOfLoadedFilesOfLocationByLocationId(location.localId);
      listOfPercentLoaded.add(percentOfLoaded);
    }
    if (allFilesLength == 0) {
      percentOfLoadingAllFiles = -1;
    } else {
      percentOfLoadingAllFiles = 100 * allFilesLoadedLenght / allFilesLength;
    }
  }

  EditHotelCubit get _cubit {
    return BlocProvider.of<EditHotelCubit>(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: Colors.black),
        centerTitle: true,
        title: Text(
          _cubit.myHotel.name,
          style: textStyle(weight: Medium5, size: 18),
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      floatingActionButton: Padding(
          padding: EdgeInsets.only(bottom: 24),
          child: FloatingActionButton(
            backgroundColor: ColorOrange,
            child: SvgPicture.asset(IMG.icons.iconPlus, width: 30, height: 30, fit: BoxFit.scaleDown),
            onPressed: () {
              controllers.forEach((controller) {
                controller.close();
              });
              pushToAddFilesAndInformationScreen(
                context: context,
                hotel: _cubit.myHotel,
                db: db,
                saveCallback: () {
                  _cubit.updateHotel();
                  widget.updateCallback();
                  setState(() {
                    _scrollPosition = 0;
                  });
                },
              );
            },
          )),
      body: _buildBody(context),
    );
  }

  _buildBody(BuildContext mainContext) {
    return NotificationListener<ScrollNotification>(
        //для сохранения scroll позиции при setState с sinc
        onNotification: (ScrollNotification scrollInfo) {
          if (scrollInfo is ScrollUpdateNotification) {
            _scrollPosition = _scrollController.position.pixels;
            //debugPrint(" _scrollPosition:$_scrollPosition");
          }
          return true;
        },
        child: FutureBuilder<void>(
            //future: futureGetAll,
            future: getAll(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(),
                );
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else {
                return BlocBuilder<EditHotelCubit, BaseCubitState>(
                  bloc: _cubit,
                  builder: (context, state) {
                    return BaseScreen(
                      state: state,
                      scrollController: _scrollController,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 10, top: 34, left: 22, right: 22),
                        child: Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: ColorWhite,
                              ),
                              child: Column(
                                // crossAxisAlignment: CrossAxisAlignment.start,
                                // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(children: [
                                    Expanded(
                                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text(
                                        "Создано: ${formatDate(stringToDate(_cubit.myHotel.createdAt) ?? DateTime(2000, 1, 1, 00, 00), format: DateFormatType.Date)}",
                                        style: textStyle(size: 12, color: ColorGreyV2),
                                      ),
                                      SizedBox(height: 14),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        children: [
                                          SvgPicture.asset(IMG.icons.iconMediaFile, fit: BoxFit.scaleDown),
                                          Text(
                                            " $allFilesLength медиафайлов",
                                            style: textStyle(size: 14),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 8),
                                    ])),
                                    if (locations.length > 0 && percentOfLoadingAllFiles != -1)
                                      Expanded(child: IndicatorOfUploading(percentUploaded: percentOfLoadingAllFiles))
                                  ]),
                                  Divider(
                                    color: Color.fromRGBO(108, 106, 106, 0.2),
                                  ),
                                  Padding(
                                      padding: EdgeInsets.symmetric(vertical: 8),
                                      child: Row(children: [
                                        Expanded(child: Text("Описание", style: textStyle(color: ColorGreyV2, size: 12), textAlign: TextAlign.start)),
                                        Expanded(
                                            child: InkWell(
                                                onTap: () {
                                                  showModalBottomSheet(
                                                      context: context,
                                                      isScrollControlled: true,
                                                      backgroundColor: Colors.white,
                                                      shape: RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32))),
                                                      builder: (BuildContext bc) {
                                                        return Container(
                                                            decoration: BoxDecoration(
                                                              borderRadius: BorderRadius.only(
                                                                topLeft: Radius.circular(32.0), // Adjust the radius as needed
                                                                topRight: Radius.circular(32.0), // Adjust the radius as needed
                                                              ),
                                                              color: Colors.white,
                                                            ),
                                                            child: HotelDescriptionBottomSheet(
                                                              description: _cubit.myHotel.description,
                                                              saveCallback: (newValue) async {
                                                                _cubit.myHotel.description = newValue;
                                                                await _cubit.updateHotel();
                                                                debugPrint("startSinc update description of my hotel");
                                                                ServiceContainer().sinkService.startSinc();
                                                              },
                                                            ));
                                                      });
                                                },
                                                child: Text("Изменить", style: textStyle(color: Colors.orange, size: 14), textAlign: TextAlign.end)))
                                      ])),
                                  if (_cubit.myHotel.description != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 16),
                                      child: Text(
                                        "${_cubit.myHotel.description}",
                                        style: textStyle(size: 14, h: 1.3),
                                      ),
                                    ),
                                  Divider(
                                    color: Color.fromRGBO(108, 106, 106, 0.2),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 8),
                            locations.isNotEmpty
                                ? SlidableAutoCloseBehavior(
                                    child: Column(
                                    children: locations.mapIndexed((index, location) {
                                      controllers.add(SlidableController(this));
                                      return Column(children: [
                                        InkWell(
                                            onTap: () {
                                              controllers.forEach((controller) {
                                                controller.close();
                                              });
                                              pushToEditHotelLocation(
                                                  context: context,
                                                  hotel: _cubit.myHotel,
                                                  location: location,
                                                  saveCallback: () async {
                                                    await _cubit.updateHotel();
                                                    widget.updateCallback();
                                                    setState(() {});
                                                  },
                                                  db: db);
                                            },
                                            child: Slidable(
                                              key: ValueKey(index),
                                              controller: controllers[index],
                                              endActionPane: ActionPane(
                                                motion: ScrollMotion(),
                                                extentRatio: 0.25,
                                                children: [
                                                  Expanded(
                                                      child: Container(
                                                    height: 150,
                                                    decoration: BoxDecoration(
                                                      color: Colors.red,
                                                    ),
                                                    child: IconButton(
                                                      icon: SvgPicture.asset(IMG.icons.iconDelete, fit: BoxFit.scaleDown),
                                                      onPressed: () {
                                                        showModalBottomSheet(
                                                            context: context,
                                                            backgroundColor: Colors.white,
                                                            builder: (BuildContext bc) {
                                                              return Container(
                                                                  decoration: BoxDecoration(
                                                                    borderRadius: BorderRadius.only(
                                                                      topLeft: Radius.circular(32.0), // Adjust the radius as needed
                                                                      topRight: Radius.circular(32.0), // Adjust the radius as needed
                                                                    ),
                                                                    color: Colors.white,
                                                                  ),
                                                                  child: Wrap(children: [
                                                                    Padding(
                                                                        padding: EdgeInsets.only(bottom: 60, left: 16, right: 16, top: 16),
                                                                        child: Column(
                                                                          children: [
                                                                            SvgPicture.asset(IMG.icons.iconDelete,
                                                                                colorFilter: ColorFilter.mode(
                                                                                  Colors.red,
                                                                                  BlendMode.srcIn,
                                                                                ),
                                                                                fit: BoxFit.scaleDown),
                                                                            SizedBox(height: 12),
                                                                            Text("Удаление записи",
                                                                                style: textStyle(size: 22, weight: FontWeight.bold)),
                                                                            SizedBox(height: 20),
                                                                            Text("Вы действительно хотите\nудалить запись?",
                                                                                textAlign: TextAlign.center, style: textStyle(size: 18)),
                                                                            SizedBox(height: 49),
                                                                            Row(
                                                                              children: [
                                                                                Expanded(
                                                                                  child: DefaultButton(
                                                                                    textSize: 18,
                                                                                    height: 55,
                                                                                    title: "Отменить",
                                                                                    scheme: DefaultButtonScheme.White,
                                                                                    onPressed: () {
                                                                                      controllers[index].close();
                                                                                      Navigator.pop(context);
                                                                                    },
                                                                                  ),
                                                                                ),
                                                                                SizedBox(width: 16),
                                                                                Expanded(
                                                                                  child: DefaultButton(
                                                                                    title: "Да, удалить",
                                                                                    textSize: 18,
                                                                                    height: 55,
                                                                                    scheme: DefaultButtonScheme.Orange,
                                                                                    onPressed: () async {
                                                                                      try {
                                                                                        await _cubit.deleteLocation(locationModel: location);
                                                                                        controllers.removeAt(index);

                                                                                        Navigator.pop(mainContext);
                                                                                        setState(() {});
                                                                                        _cubit.updateHotel();
                                                                                        widget.updateCallback();
                                                                                      } catch (e) {
                                                                                        debugPrint("UI Deleting location: $e");
                                                                                        FirebaseCrashlytics.instance.log("ui deleting location $e");
                                                                                        FirebaseCrashlytics.instance
                                                                                            .recordFlutterError(FlutterErrorDetails(exception: e));
                                                                                      }
                                                                                    },
                                                                                  ),
                                                                                ),
                                                                              ],
                                                                            )
                                                                          ],
                                                                        ))
                                                                  ]));
                                                            });
                                                      },
                                                    ),
                                                  ))
                                                ],
                                              ),
                                              child: Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Container(
                                                      width: 150,
                                                      height: 150,
                                                      decoration: BoxDecoration(
                                                        color: ColorLightGrey.withOpacity(0.5),
                                                        borderRadius: BorderRadius.circular(12),
                                                      ),
                                                      child: profileImageOfLocation(index, location, listOflistOfFiles)),
                                                  Expanded(
                                                      child: Padding(
                                                          padding: EdgeInsets.only(left: 16),
                                                          child: Column(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: [
                                                              SizedBox(height: 8),
                                                              Text(
                                                                "Создано: ${formatDate(stringToDate(location.createdAt) ?? DateTime(2000, 1, 1, 00, 00), format: DateFormatType.Date)}",
                                                                style: textStyle(size: 12, color: Color.fromRGBO(108, 106, 106, 1)),
                                                              ),
                                                              SizedBox(height: 8),
                                                              Row(
                                                                children: [
                                                                  SvgPicture.asset(getIconPathCategoty(location.idCategory), fit: BoxFit.scaleDown),
                                                                  Expanded(
                                                                      child: Text(
                                                                    " ${descriptionCategories[index]}",
                                                                    style: textStyle(size: 19, weight: FontWeight.bold),
                                                                    textAlign: TextAlign.left,
                                                                    maxLines: 1,
                                                                    //overflow: TextOverflow.ellipsis,
                                                                  )),
                                                                ],
                                                              ),
                                                              SizedBox(height: location.name.isNotEmpty ? 3 : 0),
                                                              location.name.isNotEmpty
                                                                  ? Text(location.name,
                                                                      style: textStyle(size: 14, weight: FontWeight.w500),
                                                                      textAlign: TextAlign.left,
                                                                      maxLines: 2)
                                                                  : Container(),
                                                              SizedBox(height: 8),
                                                              Row(
                                                                children: [
                                                                  SvgPicture.asset(IMG.icons.iconMediaFile, fit: BoxFit.scaleDown),
                                                                  Text(
                                                                    " ${listOflistOfFiles[index]?.length ?? 0} медиафайлов",
                                                                    style: textStyle(size: 14),
                                                                  )
                                                                ],
                                                              ),
                                                              SizedBox(height: 8),
                                                              if (listOfPercentLoaded[index] != -1)
                                                                IndicatorOfUploading(percentUploaded: listOfPercentLoaded[index])
                                                            ],
                                                          )))
                                                ],
                                              ),
                                            )),
                                        SizedBox(height: 16)
                                      ]);
                                    }).toList(),
                                  ))
                                : Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(height: 132),
                                      SvgPicture.asset(IMG.icons.iconNoLocations, fit: BoxFit.scaleDown),
                                      SizedBox(height: 16),
                                      Text(
                                        "Вы еще не добавили локацию.\nДля добавления нажмите +",
                                        style: textStyle(size: 16),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  )
                          ],
                        ),
                      ),
                    );
                  },
                );
              }
            }));
  }
}
