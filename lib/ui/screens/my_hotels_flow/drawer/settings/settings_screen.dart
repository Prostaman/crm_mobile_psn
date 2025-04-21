
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:psn.hotels.hub/db/db_manager.dart';
import 'package:psn.hotels.hub/helpers/file_utility.dart';
import 'package:psn.hotels.hub/helpers/images.gen.dart';
import 'package:psn.hotels.hub/helpers/ui_helper.dart';
import 'package:psn.hotels.hub/models/entities_database/file_model.dart';
import 'package:psn.hotels.hub/models/response_models/file_model_response.dart';
import 'package:psn.hotels.hub/services/service_container.dart';
import 'package:psn.hotels.hub/services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback setStateCallback;

  SettingsScreen({Key? key, required this.setStateCallback}) : super(key: key);
  @override
  State<SettingsScreen> createState() => _SettingsListState();
}

class _SettingsListState extends State<SettingsScreen> {
  final ValueNotifier<bool> wifi = ValueNotifier<bool>(ServiceContainer().settingsService.uploadIfWiFiEnable);

  // one must always be true, means selected. quality of files
  List<String> quality = ['720p', '1080p', '2160p', 'max'];
  late SettingsService settingsService;
  bool isLoading = false;
  bool wasDeleting = false;

  @override
  void initState() {
    super.initState();
    settingsService = ServiceContainer().settingsService;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        // PopScope doesn't work for ios, so leave it
        onWillPop: () {
          if (wasDeleting) {
            widget.setStateCallback();
          }
          return Future.value(true);
        },
        child: Stack(children: [
          Scaffold(
              appBar: AppBar(
                  title: Text(
                    'Настройки',
                    style: textStyle(size: 22, weight: Semibold6),
                  ),
                  centerTitle: true),
              body: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0), // Add padding at the start
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Divider(color: ColorDivider),
                    Row(
                      children: [
                        Text(
                          "Загрузка только по WI-FI",
                          style: textStyle(),
                        ),
                        Expanded(
                            child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                          ValueListenableBuilder(
                            valueListenable: wifi,
                            builder: (context, bool date, v) {
                              return Switch(
                                value: date,
                                activeColor: ColorGreen,
                                inactiveThumbColor: Colors.white,
                                inactiveTrackColor: Color.fromRGBO(217, 217, 217, 1),
                                trackOutlineColor: WidgetStateProperty.resolveWith((states) {
                                  if (date) {
                                    return Colors.green.withOpacity(0.5);
                                  } else {
                                    return Color.fromRGBO(217, 217, 217, 1);
                                  }
                                }),
                                onChanged: (newValue) {
                                  settingsService.saveUploadIfWifiEnable(newValue);
                                  wifi.value = newValue;
                                },
                              );
                            },
                          )
                        ]))
                      ],
                    ),
                    Divider(color: ColorDivider), // Add some spacing between the Wi-Fi switch and the text below
                    Text("Качество фото:", style: textStyle(size: 16.0)),
                    SizedBox(height: 16), // Add some spacing between the text and the toggle buttons
                    Center(
                        child: Container(
                            height: 45,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10.0), // Adjust the value as needed
                              color: Color.fromRGBO(245, 245, 245, 1), // Example background color
                            ), // Background color of the container
                            padding: EdgeInsets.all(4.0), // Padding for the container
                            child: Row(
                                children: List.generate(
                              quality.length,
                              (index) => buildQualityButton(index, quality[index]),
                            )))),
                    SizedBox(height: 32),
                    InkWell(
                        onTap: () {
                          showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  insetPadding:EdgeInsets.all(28),
                                    title: Text("Будут удалены все медиафайлы, которые отгрузились на сервер.\n\nВы уверены что хотите их удалить?\n",
                                        style: textStyle(size: 18, weight: FontWeight.w300, color: ColorTextBlackAlertDialog)),
                                    surfaceTintColor: Colors.white,
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        child:
                                            Text("Отменить", style: textStyle(size: 18, weight: FontWeight.w400, color: ColorTextBlackAlertDialog)),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          setState(() {
                                            wasDeleting = true;
                                            isLoading = true;
                                          });
                                          DBManager db = DBManager();

                                          List<FileModel> allFiles = await (await db.filesDao()).getAllFiles();
                                          for (var file in allFiles) {
                                            if (file.synced) {
                                              await FileUtility.deleteFile(file.localPath);
                                              if (file.type == FileModelType.Video && (file.thumb ?? '').isNotEmpty) {
                                                FileUtility.deleteFile(file.thumb!);
                                              }
                                              await (await db.filesDao()).deleteFile(file.localId, file.localPath);
                                            }
                                          }

                                          Navigator.pop(context);
                                          setState(() {
                                            isLoading = false;
                                          });
                                        },
                                        child: Text("Да, удалить", style: textStyle(size: 18, weight: FontWeight.w400, color: ColorTextOrange)),
                                      )
                                    ]);
                              });
                        },
                        child: Row(
                          children: [
                            SvgPicture.asset(
                              IMG.icons.iconDelete,
                              fit: BoxFit.scaleDown,
                              width: 18,
                              height: 20,
                              colorFilter: ColorFilter.mode(Colors.red, BlendMode.srcIn),
                            ),
                            SizedBox(
                              width: 8,
                            ),
                            Text(
                              "Удалить все медиафайлы",
                              style: textStyle(size: 16, weight: Regular4, color: Colors.red),
                            )
                          ],
                        )),
                  ],
                ),
              )),
          if (isLoading)
            Container(
              width: MediaQuery.of(context).size.width, // Ширина экрана
              height: MediaQuery.of(context).size.height, // Высота экрана
              color: Colors.black.withOpacity(0.5), // Прозрачный черный фон
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
        ]));
  }

  Widget buildQualityButton(int index, String text) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.0),
          color: settingsService.qualityOfFiles == index ? ColorTextOrange : null,
        ),
        child: TextButton(
          onPressed: () {
            int newIndex = index;
            if (settingsService.qualityOfFiles != newIndex) {
              settingsService.qualityOfFiles = newIndex;
              // Assuming this function is part of a StatefulWidget
              setState(() {});
            }
          },
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: settingsService.qualityOfFiles == index ? Colors.white : ColorTextOrange,
            ),
          ),
        ),
      ),
    );
  }
}
