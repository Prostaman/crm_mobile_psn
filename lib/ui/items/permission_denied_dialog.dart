import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:psn.hotels.hub/blocks/permissions_cubit/permissions_cubit.dart';
import 'package:psn.hotels.hub/helpers/ui_helper.dart';

class PermissionDeniedDialog extends StatelessWidget {
  //final MyPermissionStatus status;
  final String target;
  const PermissionDeniedDialog({Key? key, required this.target}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String title = "Empty";
    String description = "Empty";

    if (target == 'camera') {
      // if (status == MyPermissionStatus.DeniedCamera || status == MyPermissionStatus.DeniedMicrophone) {
      title = "Доступ к камере или микрофону запрещен";
      description = "Пожалуйста зайдите в настройки и разрешите доступ к камере и микрофону";
      // }
    } else {
      title = "Доступ к галерее запрещен";
      description = "Пожалуйста зайдите в настройки и разрешите доступ к галереи";
    }

    // else if (status == MyPermissionStatus.DeniedLocation) {
    //   title = "Доступ к геопозиции запрещен";
    //   description = "Пожалуйста зайдите в настройки и разрешите доступ к геопозиции";
    // }

    return AlertDialog(
        surfaceTintColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        titlePadding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 0),
        title: Text(
          title,
          style: textStyle(size: 18, weight: FontWeight.w300, color: ColorTextBlackAlertDialog),
        ),
        content: Text(description),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text("Отмена", style: textStyle(size: 18, weight: FontWeight.w400, color: ColorTextBlackAlertDialog)),
          ),
          TextButton(
            onPressed: () async {
              AppSettings.openAppSettings();
              Navigator.pop(context);
            },
            child: Text("Настройки", style: textStyle(size: 18, weight: FontWeight.w400, color: ColorTextOrange)),
          ),
        ]
        // content: Container(
        //   width: double.maxFinite,
        //   child: Column(
        //     mainAxisSize: MainAxisSize.min,
        //     children: [
        //       Container(
        //         padding: const EdgeInsets.symmetric(horizontal: 10),
        //         child: Text(description),
        //       ),
        //       SizedBox(height: 20),
        //       Row(
        //         children: [
        //           Expanded(
        //             child: DefaultButton(
        //               title: "Отмена",
        //               scheme: DefaultButtonScheme.Orange,
        //               onPressed: () async {
        //                 Navigator.pop(context);
        //               },
        //             ),
        //           ),
        //           SizedBox(width: 16),
        //           Expanded(
        //             child: DefaultButton(
        //               title: "Настройки",
        //               scheme: DefaultButtonScheme.Orange,
        //               onPressed: () async {
        //                 AppSettings.openAppSettings();
        //                 Navigator.pop(context);
        //               },
        //             ),
        //           ),
        //         ],
        //       ),
        //     ],
        //   ),
        // ),
        );
  }
}

// AlertDialog(
//                   surfaceTintColor: Colors.white,
//                   contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//                   titlePadding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 0),
//                   title: Text(
//                     "Вы уверены что хотите выйти без сохранения?",
//                     style: textStyle(size: 18, weight: FontWeight.w300, color: ColorTextBlackAlertDialog),
//                     textAlign: TextAlign.center,
//                   ),
//                   actions: [
//                     TextButton(
//                       onPressed: () {
//                         // List<FileModel> filesThatWillDelete = [];
//                         // //deleteting not saved files from memory of application
//                         // for (final file in _cubit.files) {
//                         //   if (!initialFiles.contains(file)) {
//                         //     filesThatWillDelete.add(file);
//                         //     FileUtility.deleteFile(file.localPath);
//                         //   } else if (file.isEdited) {
//                         //     FileUtility.deleteFile(file.localPath);
//                         //     file.localPath = file.oldLocalPath;
//                         //   }
//                         // }
//                         // _cubit.files.removeWhere((file) => filesThatWillDelete.contains(file));

//                         //test
//                         // await deleteteNotSavedFilesFromMemoryOfApplication();
//                         widget.saveCallback();
//                         Navigator.pop(context, true);
//                       },
//                       child: Text("Выйти", style: textStyle(size: 18, weight: FontWeight.w400, color: ColorTextBlackAlertDialog)),
//                     ),
//                     (isSyncing == true && everyModifiedFileWasUploaded() == false)
//                         ? SizedBox()
//                         : TextButton(
//                             onPressed: () async {
//                               await save();
//                               // await deleteteNotSavedFilesFromMemoryOfApplication();
//                               widget.saveCallback();
//                               Navigator.pop(context, true);
//                             },
//                             child: Text("Cохранить", style: textStyle(size: 18, weight: FontWeight.w400, color: ColorTextOrange)),
//                           ),
//                   ]);
