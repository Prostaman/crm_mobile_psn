import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:psn.hotels.hub/blocks/locations/states/location_screen_state.dart';
import 'package:psn.hotels.hub/blocks/locations/states/location_state.dart';
import 'package:psn.hotels.hub/blocks/locations/locations_cubit.dart';
import 'package:psn.hotels.hub/helpers/format_date.dart';
import 'package:psn.hotels.hub/helpers/getter_icon_path_category.dart';
import 'package:psn.hotels.hub/helpers/images.gen.dart';
import 'package:psn.hotels.hub/helpers/ui_helper.dart';
import 'package:psn.hotels.hub/models/entities_database/location_model.dart';
import 'package:psn.hotels.hub/models/entities_database/my_hotel_model.dart';
import 'package:psn.hotels.hub/services/service_container.dart';
import 'package:psn.hotels.hub/presentation/buttons/default_button.dart';
import 'package:psn.hotels.hub/presentation/items/indicator_of_uploading.dart';
import 'package:psn.hotels.hub/presentation/items/pagination_list_view.dart';
import 'package:psn.hotels.hub/presentation/routes/hotel_routes.dart';
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

class _LocationsScreenState extends State<LocationsScreen>
    with TickerProviderStateMixin {
  late List<SlidableController> controllers;
  late final LocationsCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = BlocProvider.of<LocationsCubit>(context);
    _cubit.initial(query: BaseQuery());
    controllers = [];
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocationsCubit, BaseCubitState>(
      bloc: _cubit,
      builder: (context, state) {
        // Получаем актуальные данные из стейта один раз для всего экрана
        final MyHotelModel hotel =
            state is LocationsListSuccessState ? state.myHotel : _cubit.myHotel;
        final int allFilesCount = state is LocationsListSuccessState
            ? state.allFilesLength
            : _cubit.allFilesLength;
        final double percent = state is LocationsListSuccessState
            ? state.percentLoadedFiles
            : _cubit.percentLoadedFiles;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            iconTheme: const IconThemeData(color: Colors.black),
            centerTitle: true,
            title: Text(
              hotel.name,
              style: textStyle(weight: Medium5, size: 18),
            ),
            systemOverlayStyle: SystemUiOverlayStyle.dark,
          ),
          body: Column(
            children: [
              _buildHeader(context, hotel, allFilesCount, percent),
              Expanded(
                child: SlidableAutoCloseBehavior(
                  child: PaginationListView<LocationState>(
                    cubit: _cubit,
                    padding:
                        const EdgeInsets.only(bottom: 10, left: 22, right: 22),
                    floatingActionButton: _buildFAB(hotel),
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 16),
                    itemBuilder: (context, models, index) {
                      final item = models[index];
                      if (controllers.length <= index) {
                        controllers.add(SlidableController(this));
                      }
                      return _buildLocationItem(
                          context, item, index, models, hotel);
                    },
                    emptyViewPlug: _buildEmptyState(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFAB(MyHotelModel hotel) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24, right: 24),
      child: FloatingActionButton(
        backgroundColor: ColorOrange,
        child: SvgPicture.asset(IMG.icons.iconPlus,
            width: 30, height: 30, fit: BoxFit.scaleDown),
        onPressed: () {
          controllers.forEach((controller) => controller.close());
          pushToAddFilesAndInformationScreen(
            context: context,
            hotel: hotel,
            db: _cubit.db,
            saveCallback: () {
              _cubit.reload();
              widget.updateCallback();
            },
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, MyHotelModel hotel, int filesCount,
      double percent) {
    return Padding(
      padding: const EdgeInsets.only(top: 34, left: 22, right: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Создано: ${formatDate(stringToDate(hotel.createdAt) ?? DateTime(2000, 1, 1, 00, 00), format: DateFormatType.Date)}",
                    style: textStyle(size: 12, color: ColorGreyV2),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SvgPicture.asset(IMG.icons.iconMediaFile,
                          fit: BoxFit.scaleDown),
                      Text(
                        " $filesCount медиафайлов",
                        style: textStyle(size: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            if (percent != -1)
              Expanded(child: IndicatorOfUploading(percentUploaded: percent))
          ]),
          const Divider(color: Color.fromRGBO(108, 106, 106, 0.2)),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text("Описание",
                      style: textStyle(color: ColorGreyV2, size: 12),
                      textAlign: TextAlign.start),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () =>
                        _showEditDescriptionBottomSheet(context, hotel),
                    child: Text("Изменить",
                        style: textStyle(color: Colors.orange, size: 14),
                        textAlign: TextAlign.end),
                  ),
                )
              ],
            ),
          ),
          if (hotel.description != null && hotel.description!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                "${hotel.description}",
                style: textStyle(size: 14, h: 1.3),
              ),
            ),
          const Divider(color: Color.fromRGBO(108, 106, 106, 0.2)),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildLocationItem(BuildContext context, LocationState item, int index,
      List<LocationState> models, MyHotelModel hotel) {
    final location = item.location;
    return InkWell(
      key: ValueKey(location.localId),
      onTap: () {
        controllers.forEach((controller) => controller.close());
        pushToEditHotelLocation(
          context: context,
          hotel: hotel,
          location: location,
          db: _cubit.db,
          saveCallback: () async {
            _cubit.reload();
            widget.updateCallback();
          },
        );
      },
      child: Slidable(
        controller: controllers[index],
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          extentRatio: 0.25,
          children: [
            Expanded(
              child: Container(
                height: 150,
                decoration: const BoxDecoration(color: Colors.red),
                child: IconButton(
                  icon: SvgPicture.asset(IMG.icons.iconDelete,
                      fit: BoxFit.scaleDown),
                  onPressed: () =>
                      _showDeleteConfirmation(context, location, index),
                ),
              ),
            )
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: applyOpacity(ColorLightGrey, 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: profileImageOfLocation(
                  index, location, models.map((m) => m.files).toList()),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      "Создано: ${formatDate(stringToDate(location.createdAt) ?? DateTime(2000, 1, 1, 00, 00), format: DateFormatType.Date)}",
                      style: textStyle(
                          size: 12,
                          color: const Color.fromRGBO(108, 106, 106, 1)),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        SvgPicture.asset(
                            getIconPathCategoty(location.idCategory),
                            fit: BoxFit.scaleDown),
                        Expanded(
                          child: Text(
                            " ${item.categoryDescription}",
                            style: textStyle(size: 19, weight: FontWeight.bold),
                            textAlign: TextAlign.left,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    if (location.name.isNotEmpty)
                      Text(location.name,
                          style: textStyle(size: 14, weight: FontWeight.w500),
                          textAlign: TextAlign.left,
                          maxLines: 2),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        SvgPicture.asset(IMG.icons.iconMediaFile,
                            fit: BoxFit.scaleDown),
                        Text(
                          " ${item.files.length} медиафайлов",
                          style: textStyle(size: 14),
                        )
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (item.percentLoaded != -1)
                      IndicatorOfUploading(percentUploaded: item.percentLoaded)
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 132),
        SvgPicture.asset(IMG.icons.iconNoLocations, fit: BoxFit.scaleDown),
        const SizedBox(height: 16),
        Text(
          "Вы еще не добавили локацию.\nДля добавления нажмите +",
          style: textStyle(size: 16),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  void _showEditDescriptionBottomSheet(
      BuildContext context, MyHotelModel hotel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(32), topRight: Radius.circular(32))),
      builder: (BuildContext bc) {
        return HotelDescriptionBottomSheet(
          description: hotel.description,
          saveCallback: (newDescription) async {
            await _cubit.updateDescriptionMyHotel(newDescription ?? '');
            ServiceContainer().sinkService.startSynchronization();
          },
        );
      },
    );
  }

  void _showDeleteConfirmation(
      BuildContext context, LocationModel location, int index) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      builder: (BuildContext bc) {
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 60),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(IMG.icons.iconDelete,
                  colorFilter:
                      const ColorFilter.mode(Colors.red, BlendMode.srcIn),
                  fit: BoxFit.scaleDown),
              const SizedBox(height: 12),
              Text("Удаление записи",
                  style: textStyle(size: 22, weight: FontWeight.bold)),
              const SizedBox(height: 20),
              Text("Вы действительно хотите\nудалить запись?",
                  textAlign: TextAlign.center, style: textStyle(size: 18)),
              const SizedBox(height: 49),
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
                  const SizedBox(width: 16),
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
                          Navigator.pop(context);
                          widget.updateCallback();
                        } catch (e) {
                          FirebaseCrashlytics.instance
                              .log("presentation deleting location $e");
                        }
                      },
                    ),
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }
}
