import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:psn.hotels.hub/blocks/edit_hotel/edit_hotel_cubit.dart';
import 'package:psn.hotels.hub/blocks/hotel_location/my_hotel_cubit.dart';
import 'package:psn.hotels.hub/db/db_manager.dart';
import 'package:psn.hotels.hub/models/entities_database/location_model.dart';
import 'package:psn.hotels.hub/models/entities_database/my_hotel_model.dart';
import 'package:psn.hotels.hub/ui/routes/base_routes.dart';
import 'package:psn.hotels.hub/ui/screens/my_hotels_flow/add_location/add_files_and_information_screen.dart';
import 'package:psn.hotels.hub/ui/screens/my_hotels_flow/full_media_preview_screen/full_media_preview_slider.dart';
import 'package:psn.hotels.hub/ui/screens/my_hotels_flow/locations/locations_screen.dart';
import '../screens/my_hotels_flow/drawer/settings/settings_screen.dart';

pushToHotelSettings({required BuildContext context, required VoidCallback setStateCallback}) {
  pushTo(screen: SettingsScreen(setStateCallback:setStateCallback), context: context);
}

pushToHotelLocationsScreen({
  required BuildContext context,
  required MyHotelModel model,
  required VoidCallback updateCallback,
  required DBManager db,
}) {
  pushTo(
    screen: BlocProvider(
      create: (context) => EditHotelCubit(myHotel: model,db: db),
      child: LocationsScreen(updateCallback: updateCallback),
    ),
    context: context,
  );
}

pushToAddFilesAndInformationScreen(
    {required BuildContext context, required MyHotelModel hotel, required VoidCallback saveCallback, 
    required DBManager db
    }) {
  pushTo(
    screen: BlocProvider(
      create: (context) => MyHotelCubit(myHotelModel: hotel, db: db),
      child: AddFilesAndInformationScreen(
        saveCallback: saveCallback
      ),
    ),
    context: context,
  );
}

pushToEditHotelLocation(
    {required BuildContext context,
    required MyHotelModel hotel,
    required LocationModel location,
    required VoidCallback saveCallback,
    required DBManager db}) {
  pushTo(
    screen: BlocProvider(
      create: (context) => MyHotelCubit(myHotelModel: hotel, location: location, db: db),
      child: AddFilesAndInformationScreen(
        saveCallback: saveCallback
      ),
    ),
    context: context,
  );
}

showFullMediaPreviewSlider(context, _cubit, setStateCallback,
    [initialIndex = 0]) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) {
        return FullMediaPreviewSlider(
          _cubit,
          setStateCallback,
          initialIndex,
          PageController(initialPage: initialIndex),
        );
      },
    ),
  );
}


