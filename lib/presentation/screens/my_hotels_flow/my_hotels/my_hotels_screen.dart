import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:psn.hotels.hub/blocks/my_hotels/my_hotels_cubit.dart';
import 'package:psn.hotels.hub/blocks/my_hotels/my_hotel_state.dart';
import 'package:psn.hotels.hub/helpers/format_date.dart';
import 'package:psn.hotels.hub/helpers/images.gen.dart';
import 'package:psn.hotels.hub/presentation/ui_helper.dart';
import 'package:psn.hotels.hub/presentation/items/pagination_list_view.dart';
import 'package:psn.hotels.hub/presentation/routes/hotel_routes.dart';
import 'package:psn.hotels.hub/presentation/screens/my_hotels_flow/drawer/default_drawer.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:psn.hotels.hub/presentation/screens/my_hotels_flow/my_hotels/profile_image_of_my_hotel_widget.dart';
import 'package:psn.hotels.hub/presentation/screens/my_hotels_flow/my_hotels/delete_hotel_dialog.dart';

import '../../../../blocks/base_cubit/base_cubit.dart';
import '../../../items/indicator_of_uploading.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'add_search_hotel/show_add_hotels_bottom_sheet.dart';

class MyHotelsScreen extends StatefulWidget {
  MyHotelsScreen({Key? key}) : super(key: key);

  @override
  _MyHotelsScreenState createState() => _MyHotelsScreenState();
}

class _MyHotelsScreenState extends State<MyHotelsScreen>
    with TickerProviderStateMixin {
  late List<SlidableController> controllers;
  late final MyHotelsCubit _cubit;

  //поиск
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cubit = BlocProvider.of<MyHotelsCubit>(context);
    _cubit.initial(query: BaseQuery());
    controllers = [];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
          title: _isSearching
              ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Поиск отеля...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    fillColor: const Color.fromRGBO(245, 245, 245, 1),
                    filled: true,
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    hintStyle: textStyle(color: Colors.grey),
                  ),
                  style: textStyle(color: Colors.black),
                  onChanged: (value) {
                    _cubit.query.search = value;
                    _cubit.reload();
                  },
                )
              : Text("Мои отели",
                  style: textStyle(
                      weight: Medium5, size: 22, color: Colors.black)),
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          actions: [
            IconButton(
              icon: Icon(_isSearching ? Icons.close : Icons.search),
              onPressed: () {
                setState(() {
                  _isSearching = !_isSearching;
                  if (!_isSearching) {
                    _searchController.clear();
                    _cubit.query.search = "";
                    _cubit.reload();
                  }
                });
              },
            ),
          ],
        ),
        drawer: AppDrawer(setStateCallback: (() async {
          await _cubit.reload();
        })),
        body: _buildBody(context));
  }

  _buildBody(BuildContext mainContext) {
    const double sizeOfSide = 154;
    return SlidableAutoCloseBehavior(
      child: PaginationListView<MyHotelState>(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        cubit: _cubit,
        floatingActionButton: Padding(
            padding: EdgeInsets.only(bottom: 24, right: 24),
            child: FloatingActionButton(
              backgroundColor: ColorOrange,
              child: SvgPicture.asset(IMG.icons.iconPlus,
                  width: 30, height: 30, fit: BoxFit.scaleDown),
              onPressed: () {
                controllers.forEach((controller) {
                  controller.close();
                });
                showAddHotelsBottomSheet(context: context, cubit: _cubit);
              },
            )),
        separatorBuilder: (context, index) {
          return Column(children: [
            SizedBox(height: 6),
            Divider(color: ColorDivider),
            SizedBox(height: 6)
          ]);
        },
        itemBuilder: (context, models, index) {
          controllers.add(SlidableController(this));
          return InkWell(
            key: ValueKey(models[index].base.id),
            onTap: () {
              controllers.forEach((controller) => controller.close());
              pushToLocationsScreen(
                context: context,
                model: models[index].base,
                updateCallback: () async {
                  await _cubit.updateSingleMyHotel(models[index].base.id);
                },
              );
            },
            child: Container(
                height: 154,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Slidable(
                  key: ValueKey(models[index].base.id),
                  controller: controllers[index],
                  endActionPane: ActionPane(
                    motion: ScrollMotion(),
                    extentRatio: 0.25,
                    children: [
                      Expanded(
                          child: Container(
                        height: sizeOfSide,
                        decoration: BoxDecoration(color: Colors.red),
                        child: IconButton(
                          icon: SvgPicture.asset(IMG.icons.iconDelete,
                              fit: BoxFit.scaleDown),
                          onPressed: () {
                            showDeleteHotelDialog(
                              context: mainContext,
                              cubit: _cubit,
                              index: index,
                              controllers: controllers,
                            );
                          },
                        ),
                      ))
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                          width: sizeOfSide,
                          height: sizeOfSide,
                          decoration: BoxDecoration(
                            color: applyOpacity(ColorLightGrey, 0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: profileImageOMyfHotel(models[index].base, [])),
                      Expanded(
                          child: Padding(
                              padding: EdgeInsets.only(left: 18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 4),
                                  Text(
                                    "Создано: ${formatDate(stringToDate(models[index].base.createdAt) ?? DateTime(2000, 1, 1), format: DateFormatType.Date)}",
                                    style: textStyle(
                                        size: 12,
                                        color:
                                            Color.fromRGBO(108, 106, 106, 1)),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    models[index].base.name,
                                    style: textStyle(
                                        size: 19, weight: FontWeight.bold),
                                    textAlign: TextAlign.left,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    "${models[index].base.country}, ${models[index].base.resort}",
                                    style: textStyle(
                                        size: 12,
                                        color:
                                            Color.fromRGBO(108, 106, 106, 1)),
                                  ),
                                  SizedBox(height: 9),
                                  Row(
                                    children: [
                                      SvgPicture.asset(IMG.icons.iconMediaFile,
                                          fit: BoxFit.scaleDown),
                                      Text(
                                        " ${models[index].files.length} медиафайлов",
                                        style: textStyle(size: 14),
                                      )
                                    ],
                                  ),
                                  if (models[index].files.length > 0 &&
                                      models[index].percentUploaded != -1)
                                    IndicatorOfUploading(
                                        percentUploaded:
                                            models[index].percentUploaded)
                                ],
                              )))
                    ],
                  ),
                )),
          );
        },
        emptyViewPlug: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(IMG.icons.iconMyHotelsEmptyLits,
                fit: BoxFit.scaleDown),
            SizedBox(height: 16),
            Text(
              "Вы еще не добавили отели.\nДля начала работы нажмите +",
              style: textStyle(size: 18),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Padding(
              padding: EdgeInsets.only(left: 32.0),
              child: SvgPicture.asset(IMG.icons.arrowDown,
                  width: 100, height: 100, fit: BoxFit.scaleDown),
            )
          ],
        ),
      ),
    );
  }
}
