import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_svg/svg.dart';
import 'package:psn.hotels.hub/blocks/my_hotels/my_hotels_cubit.dart';
import 'package:psn.hotels.hub/helpers/images.gen.dart';
import 'package:psn.hotels.hub/helpers/ui_helper.dart';
import 'package:psn.hotels.hub/presentation/buttons/default_button.dart';

void showDeleteHotelDialog({
  required BuildContext context,
  required MyHotelsCubit cubit,
  required int index,
  required List<SlidableController> controllers,
}) {
  showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(32.0),
                topRight: Radius.circular(32.0),
              ),
              color: Colors.white,
            ),
            child: Wrap(children: [
              Padding(
                  padding:
                      EdgeInsets.only(bottom: 60, left: 23, right: 23, top: 16),
                  child: Column(
                    children: [
                      SvgPicture.asset(IMG.icons.iconDelete,
                          colorFilter:
                              ColorFilter.mode(Colors.red, BlendMode.srcIn),
                          fit: BoxFit.scaleDown),
                      SizedBox(height: 12),
                      Text("Удаление записи",
                          style: textStyle(size: 22, weight: FontWeight.bold)),
                      SizedBox(height: 20),
                      Text("Вы действительно хотите\nудалить запись?",
                          textAlign: TextAlign.center,
                          style: textStyle(size: 18)),
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
                                Navigator.pop(bc);
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
                                  await cubit.removeHotel(
                                      myHotel: cubit.models[index].base);
                                  controllers.removeAt(index);
                                  Navigator.pop(bc);
                                } catch (e) {
                                  debugPrint("UI Deleting hotel: $e");
                                  FirebaseCrashlytics.instance
                                      .log("presentation deleting hotel $e");
                                  FirebaseCrashlytics.instance
                                      .recordFlutterError(
                                          FlutterErrorDetails(exception: e));
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
}
