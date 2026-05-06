import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:psn.hotels.hub/presentation/blocks/permissions_cubit/permissions_cubit.dart';
import 'package:psn.hotels.hub/infrastructure/images.gen.dart';
import 'package:psn.hotels.hub/presentation/ui_helper.dart';
import 'package:psn.hotels.hub/domain/services/service_container.dart';
import 'package:psn.hotels.hub/presentation/buttons/default_button.dart';

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
                style:
                    textStyle(size: 18, color: Color.fromRGBO(43, 54, 65, 1)),
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
    final permissionsCubit = BlocProvider.of<PermissionsCubit>(context);
    await permissionsCubit.requestAllPermissions();

    await ServiceContainer().authService.checkAutorization();
  }
}
