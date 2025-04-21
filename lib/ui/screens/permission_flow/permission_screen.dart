import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:psn.hotels.hub/helpers/images.gen.dart';
import 'package:psn.hotels.hub/helpers/ui_helper.dart';
import 'package:psn.hotels.hub/services/service_container.dart';
import 'package:psn.hotels.hub/ui/buttons/default_button.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorWhite,
      body: _buildBody(context: context),
    );
  }

  _buildBody({required BuildContext context}) {
    return Stack(
      children: [
        Center(
          child: SvgPicture.asset(IMG.icons.authBack, fit: BoxFit.scaleDown),
        ),
        Positioned.fill(
          left: 16,
          right: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 44),
              SvgPicture.asset(IMG.icons.logoPNG, fit: BoxFit.scaleDown),
              Spacer(),
              Text(
                "Для доступа к полному функционалу приложения надо предоставить доступ к камере, микрофону и галерее, а также желательно к вашей геопозиции.",
                style: textStyle(size: 18, color: Color.fromRGBO(43, 54, 65, 1)),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 76),
              Row(
                children: [
                  Expanded(
                    child: DefaultButton(
                      key: Key('nextPermission'),
                      title: "Далее",
                      textSize: 22,
                      height: 56,
                      scheme: DefaultButtonScheme.Orange,
                      onPressed: () {
                        _nextAction(context);
                      },
                    ),
                  )
                ],
              ),
              SafeArea(child: SizedBox(height: 16)),
            ],
          ),
        ),
      ],
    );
  }

  _nextAction(context) async {
    await Permission.camera.request();
    Future.delayed(Duration(milliseconds: 500)); //ибо возникает краш на платформе iOS при запросе
    await Permission.microphone.request();
    Future.delayed(Duration(milliseconds: 500));
    await Permission.location.request();
    if (Platform.isIOS) {
      await Permission.photos.request();
    } else {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      if (androidInfo.version.sdkInt <= 32) {
        await Permission.storage.request();
      } else {
        await Permission.photos.request();
      }
    }
    Future.delayed(Duration(milliseconds: 500));
    await ServiceContainer().authService.checkAutorization();
    // var status = await BlocProvider.of<PermissionsCubit>(context).checkPermissions();
    // if (status == MyPermissionStatus.Granted) {
    //   //тут какая-то хрень, но работает
    //   //await ServiceContainer().authService.loadData();
    //   await ServiceContainer().authService.checkAutorization();
    // } else if (status == MyPermissionStatus.Undetermined) {
    //   _nextAction(context);
    // } else {
    //   showDialog(
    //     context: context,
    //     builder: (context) {
    //       return PermissionDeniedDialog(status: status);
    //     },
    //   );
    // }
  }
}
