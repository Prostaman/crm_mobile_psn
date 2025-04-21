import 'dart:async';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:psn.hotels.hub/blocks/my_hotels/my_hotels_cubit.dart';
import 'package:psn.hotels.hub/db/db_manager.dart';
//import 'package:psn.hotels.hub/helpers/firebase/firebase_crashlytics_helper.dart';
import 'package:psn.hotels.hub/helpers/format_date.dart';
import 'package:psn.hotels.hub/helpers/images.gen.dart';
import 'package:psn.hotels.hub/helpers/ui_helper.dart';
import 'package:psn.hotels.hub/models/entities_database/file_model.dart';
import 'package:psn.hotels.hub/models/entities_database/location_model.dart';
import 'package:psn.hotels.hub/models/entities_database/my_hotel_model.dart';
import 'package:psn.hotels.hub/services/service_container.dart';
import 'package:psn.hotels.hub/ui/buttons/default_button.dart';
import 'package:psn.hotels.hub/ui/items/pagination_list_view.dart';
import 'package:psn.hotels.hub/ui/routes/hotel_routes.dart';
import 'package:psn.hotels.hub/ui/screens/my_hotels_flow/drawer/default_drawer.dart';
import 'package:psn.hotels.hub/ui/screens/my_hotels_flow/my_hotels/add_hotels_bottom_sheet.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:psn.hotels.hub/ui/screens/my_hotels_flow/my_hotels/profile_image_of_my_hotel_widget.dart';

import '../../../items/indicator_of_uploading.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MyHotelsScreen extends StatefulWidget {
  MyHotelsScreen({Key? key}) : super(key: key);

  @override
  _MyHotelsScreenState createState() => _MyHotelsScreenState();
}

class _MyHotelsScreenState extends State<MyHotelsScreen> with TickerProviderStateMixin {
  StreamSubscription? subscriptionSinc;
  late DBManager db;
  List<SlidableController> controllers = [];

  late ScrollController _scrollController;
  double _scrollPosition = 0;

  @override
  void initState() {
    FirebaseCrashlytics.instance.setUserIdentifier(ServiceContainer().authService.user?.userName ?? "No auth");
    db = DBManager();
    subscriptionSinc = _cubit.services.sinkService.syncSuccess.stream.listen((item) {
      //_cubit.reload();
      setState(() {
        //debugPrint("initialScrollOffset MyHotels: $_scrollPosition");
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

  MyHotelsCubit get _cubit {
    return BlocProvider.of<MyHotelsCubit>(context);
  }

  // PermissionsCubit get _permissionsCubit {
  //   return BlocProvider.of<PermissionsCubit>(context);
  // }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: ColorWhite,
        appBar: AppBar(
          backgroundColor: ColorWhite,
          surfaceTintColor: ColorWhite,
          iconTheme: IconThemeData(color: Colors.black),
          centerTitle: true,
          title: Text("Мои отели", style: textStyle(weight: Medium5, size: 22, color: Colors.black)),
          systemOverlayStyle: SystemUiOverlayStyle.dark,
        ),
        floatingActionButton: Padding(
            padding: EdgeInsets.only(bottom: 24),
            child: FloatingActionButton(
              backgroundColor: ColorOrange,
              child: SvgPicture.asset(IMG.icons.iconPlus, width: 30, height: 30, fit: BoxFit.scaleDown),
              onPressed: () {
                // FirebaseCrashlytics.instance.log('Iphone_release');
                // FirebaseCrashlytics.instance.recordFlutterError(FlutterErrorDetails(exception: Exception('Testing')));

                controllers.forEach((controller) {
                  controller.close();
                });
                _showHotelsBottomSheet();
              },
            )),
        drawer: AppDrawer(setStateCallback: (() async {
          await _cubit.reload();
          setState(() {
            debugPrint("Was updating");
          });
        })),
        body: _buildBody(context));
  }

  _buildBody(BuildContext mainContext) {
    double heightOfItem = 150;
    return NotificationListener<ScrollNotification>(
        //для сохранения scroll позиции при setState с sinc
        onNotification: (ScrollNotification scrollInfo) {
          if (scrollInfo is ScrollUpdateNotification) {
            _scrollPosition = _scrollController.position.pixels;
            //debugPrint(" new _scrollPosition:$_scrollPosition");
          }
          return true;
        },
        child: SlidableAutoCloseBehavior(
          child: PaginationListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            cubit: _cubit,
            scrollController: _scrollController,
            separatorBuilder: (context, index) {
              return Column(children: [SizedBox(height: 6), Divider(color: ColorDivider), SizedBox(height: 6)]);
            },
            itemBuilder: (context, index) {
              var myHotelModel = _cubit.modelByIndex(index: index);
              controllers.add(SlidableController(this));
              if (myHotelModel != null)
                return InkWell(
                  onTap: () {
                    controllers.forEach((controller) {
                      controller.close();
                    });
                    pushToHotelLocationsScreen(
                      context: context,
                      model: myHotelModel,
                      db: db,
                      updateCallback: () async {
                        await _cubit.reload();
                      },
                    );
                  },
                  child: Container(
                      height: heightOfItem,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: FutureBuilder<List<dynamic>>(
                          future: Future.wait([
                            myHotelModel.getAllFiles(db),
                            myHotelModel.getLocations(db),
                            myHotelModel.getPercentLoadedOfAllFilesOfMyHotel(db),
                            myHotelModel.getCountryAndResort(db),
                          ]),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return Center(
                                child: CircularProgressIndicator(),
                              );
                            } else if (snapshot.hasError) {
                              return Text('Error: ${snapshot.error}'); // Show error message if fetching data fails
                            } else {
                              List<dynamic> data = snapshot.data!;
                              List<FileModel> files = data[0] ?? [];
                              List<LocationModel> locations = data[1] ?? [];
                              double percentUploaded = data[2];
                              String country = data[3][0];
                              String resort = data[3][1];

                              return Slidable(
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
                                              context: mainContext,
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
                                                          padding: EdgeInsets.only(bottom: 60, left: 23, right: 23, top: 16),
                                                          child: Column(
                                                            children: [
                                                              SvgPicture.asset(IMG.icons.iconDelete,
                                                                  colorFilter: ColorFilter.mode(Colors.red, BlendMode.srcIn), fit: BoxFit.scaleDown),
                                                              SizedBox(height: 12),
                                                              Text("Удаление записи", style: textStyle(size: 22, weight: FontWeight.bold)),
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
                                                                  SizedBox(width: 8),
                                                                  Expanded(
                                                                    child: DefaultButton(
                                                                      title: "Да, удалить",
                                                                      textSize: 18,
                                                                      height: 55,
                                                                      scheme: DefaultButtonScheme.Orange,
                                                                      onPressed: () async {
                                                                        try {
                                                                         
                                                                          await _cubit.removeHotel(myHotel: myHotelModel);
                                                                          controllers.removeAt(index);

                                                                          Navigator.pop(mainContext);
                                                                        } catch (e) {
                                                                          debugPrint("UI Deleting hotel: $e");
                                                                          FirebaseCrashlytics.instance.log("ui deleting hotel $e");
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
                                        child: profileImageOMyfHotel(myHotelModel, files)),
                                    Expanded(
                                        child: Padding(
                                            padding: EdgeInsets.only(left: 18),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                SizedBox(height: 4),
                                                Text(
                                                  "Создано: ${formatDate(stringToDate(myHotelModel.createdAt) ?? DateTime(2000, 1, 1, 00, 00), format: DateFormatType.Date)}",
                                                  style: textStyle(size: 12, color: Color.fromRGBO(108, 106, 106, 1)),
                                                ),
                                                SizedBox(height: 6),
                                                Text(
                                                  myHotelModel.name,
                                                  style: textStyle(size: 19, weight: FontWeight.bold),
                                                  textAlign: TextAlign.left,
                                                ),
                                                SizedBox(height: 6),
                                                Text(
                                                  "$country, $resort",
                                                  style: textStyle(size: 12, color: Color.fromRGBO(108, 106, 106, 1)),
                                                ),
                                                SizedBox(height: 9),
                                                Row(
                                                  children: [
                                                    SvgPicture.asset(IMG.icons.iconMediaFile, fit: BoxFit.scaleDown),
                                                    Text(
                                                      " ${files.length} медиафайлов",
                                                      style: textStyle(size: 14),
                                                    )
                                                  ],
                                                ),
                                                if (locations.length > 0 && percentUploaded != -1)
                                                  IndicatorOfUploading(percentUploaded: percentUploaded)
                                              ],
                                            )))
                                  ],
                                ),
                              );
                            }
                          })),
                );
              return null;
            },
            emptyViewPlug: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(IMG.icons.iconMyHotelsEmptyLits, fit: BoxFit.scaleDown),
                SizedBox(height: 16),
                Text(
                  "Вы еще не добавили отели.\nДля начала работы нажмите +",
                  style: textStyle(size: 18),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                Padding(
                  padding: EdgeInsets.only(left: 32.0),
                  child: SvgPicture.asset(IMG.icons.arrowDown, width: 100, height: 100, fit: BoxFit.scaleDown),
                )
              ],
            ),
          ),
        ));
  }

  _showHotelsBottomSheet() async {
    await Permission.location.request();
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
              child: HotelsBottomSheet(
                onTapCallback: (selectedHotel) async {
                  if (selectedHotel != null) await _cubit.addHotel(hotel: selectedHotel);
                  MyHotelModel myNewHotelModel = MyHotelModel.fromMap((await (await db.myHotelsDao()).findMyHotelById(selectedHotel!.id))!);
                  pushToHotelLocationsScreen(
                    context: context,
                    model: myNewHotelModel,
                    db: db,
                    updateCallback: () async {
                      await _cubit.reload();
                    },
                  );
                },
              ));
        });
  }
}
