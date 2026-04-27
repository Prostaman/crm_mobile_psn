import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:psn.hotels.hub/blocks/my_hotels/my_hotels_cubit.dart';
import 'package:psn.hotels.hub/models/entities_database/my_hotel_model.dart';
import 'package:psn.hotels.hub/ui/routes/hotel_routes.dart';

import 'add_search_hotel_bottom_sheet.dart';

void showAddHotelsBottomSheet({
  required BuildContext context,
  required MyHotelsCubit cubit,
}) async {
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
            child: AddSearchHotelBottomSheet(
              onTapCallback: (idSelectedHotel) async {
                MyHotelModel? myNewHotelModel =
                    await cubit.addMyHotel(hotelID: idSelectedHotel);
                if (myNewHotelModel != null) {
                  if (context.mounted) {
                    pushToLocationsScreen(
                      context: context,
                      model: myNewHotelModel,
                      db: cubit.db,
                      updateCallback: () async {
                        // await cubit.updateSingleHotel(myNewHotelModel.id);
                      },
                    );
                  }
                }
              },
            ));
      });
}
