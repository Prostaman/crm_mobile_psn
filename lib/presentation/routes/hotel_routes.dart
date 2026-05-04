import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:psn.hotels.hub/blocks/locations/locations_cubit.dart';
import 'package:psn.hotels.hub/blocks/content/content_cubit.dart';
import 'package:psn.hotels.hub/models/entities_database/location_model.dart';
import 'package:psn.hotels.hub/models/entities_database/my_hotel_model.dart';
import 'package:psn.hotels.hub/presentation/routes/base_routes.dart';
import 'package:psn.hotels.hub/presentation/screens/my_hotels_flow/content/content_screen.dart';
import 'package:psn.hotels.hub/presentation/screens/my_hotels_flow/full_media_preview_screen/full_media_preview_slider.dart';
import 'package:psn.hotels.hub/presentation/screens/my_hotels_flow/locations/locations_screen.dart';
import '../screens/my_hotels_flow/drawer/settings/settings_screen.dart';

pushToHotelSettings(
    {required BuildContext context, required VoidCallback setStateCallback}) {
  pushTo(screen: SettingsScreen(), context: context);
}

pushToLocationsScreen({
  required BuildContext context,
  required MyHotelModel model,
  required VoidCallback updateCallback,
}) {
  pushTo(
    screen: BlocProvider(
      create: (context) => LocationsCubit(myHotel: model),
      child: LocationsScreen(updateCallback: updateCallback),
    ),
    context: context,
  );
}

pushToCreateLocationWithContentScreen(
    {required BuildContext context,
    required MyHotelModel hotel,
    required VoidCallback saveCallback}) {
  pushTo(
    screen: BlocProvider(
      create: (context) => ContentCubit(myHotel: hotel)..init(),
      child: ContentScreen(saveCallback: saveCallback),
    ),
    context: context,
  );
}

pushToEditLocationContent(
    {required BuildContext context,
    required MyHotelModel hotel,
    required LocationModel location,
    required VoidCallback saveCallback}) {
  pushTo(
    screen: BlocProvider(
      create: (context) =>
          ContentCubit(myHotel: hotel, location: location)..init(),
      child: ContentScreen(saveCallback: saveCallback),
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
