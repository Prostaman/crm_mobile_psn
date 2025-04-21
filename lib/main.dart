import 'dart:async';
import 'package:app_version_update/app_version_update.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:psn.hotels.hub/blocks/authentication/sign_in_cubit.dart';
import 'package:psn.hotels.hub/blocks/base_cubit/base_cubit.dart';
import 'package:psn.hotels.hub/blocks/flow_cubit/flow_cubit.dart';
import 'package:psn.hotels.hub/blocks/hotels/hotels_dialog_cubit.dart';
import 'package:psn.hotels.hub/blocks/my_hotels/my_hotels_cubit.dart';
import 'package:psn.hotels.hub/blocks/permissions_cubit/permissions_cubit.dart';
import 'package:psn.hotels.hub/services/service_container.dart';
import 'package:psn.hotels.hub/ui/screens/auth_flow/sign_in_screen.dart';
import 'package:psn.hotels.hub/ui/screens/my_hotels_flow/my_hotels/my_hotels_screen.dart';
import 'package:psn.hotels.hub/ui/screens/permission_flow/permission_screen.dart';
import 'package:psn.hotels.hub/ui/screens/splash_screen.dart';
import 'helpers/firebase/firebase_initialization.dart';
import 'helpers/location_helper.dart';
import 'helpers/shared_preferences_utils.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'helpers/ui_helper.dart';
import 'main.reflectable.dart';
import 'ui/theme/color_schemes.g.dart';

void main() async {
  initializeReflectable();
  // Точка входа
  WidgetsFlutterBinding.ensureInitialized();

  await initFirebase();
  await SharedPrefUtils().init();
  // Инициализация сервиса локализации
  LocationHelper.init();

  //установка ориентации приложения
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  // устанавливаем системные стили
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light.copyWith(
      systemNavigationBarColor: Colors.grey[200],
      statusBarColor: Colors.grey[200],
      statusBarBrightness: Brightness.light,
      statusBarIconBrightness: Brightness.dark));

  Bloc.observer = MainBlocDelegate();
  runApp(
    MultiBlocProvider(
        providers: _providers(),
        child: runZonedGuarded<Widget>(
              () {
                return PoehalisnamiApp();
              },
              FirebaseCrashlytics.instance.recordError,
            ) ??
            Container()),
  );
}


_providers() {
  return <BlocProvider<dynamic>>[
    // авторизация
    BlocProvider<FlowCubit>(create: (context) => ServiceContainer().authService.flowCubit..check()),
    // кубит с отелями
    BlocProvider<HotelsDialogCubit>(create: (context) => HotelsDialogCubit()),
    // кубит с доступами - микрофон, камера, и тд
    BlocProvider<PermissionsCubit>(create: (context) => PermissionsCubit()),
  ];
}

bool wasOfferToUpdate = false;
_checkUpdate(BuildContext context) {
  //проверка обновлений
  final appleId = '6480569224'; // If this value is null, its packagename will be considered
  final playStoreId = 'psn.hotels.app'; // If this value is null, its packagename will be considered
  final country = 'ua'; // If this value is null 'us' will be the default value
  AppVersionUpdate.checkForUpdates(appleId: appleId, playStoreId: playStoreId, country: country).then((data) async {
    wasOfferToUpdate = true;
    if (data.canUpdate!) {
      AppVersionUpdate.showAlertUpdate(
          appVersionResult: data,
          context: context,
          title: 'Доступна новая версия',
          titleTextStyle: textStyle(size: 16, weight: FontWeight.w400),
          cancelButtonStyle: ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(
                Color.fromRGBO(28, 28, 28, 0.2),
              ),
              textStyle: WidgetStatePropertyAll(textStyle(size: 16, weight: FontWeight.w400)),
              fixedSize: WidgetStatePropertyAll(Size(109, 34))
              ),
          updateButtonStyle: ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(Color.fromRGBO(225, 108, 58, 1)),
              textStyle: WidgetStatePropertyAll(textStyle(size: 16, weight: FontWeight.w400)),
              fixedSize: WidgetStatePropertyAll(Size(109, 34))
              ),
          content: 'Обновить сейчас?',
          cancelButtonText: 'Позже',
          updateButtonText: 'Обновить');
    }
  });
}

class PoehalisnamiApp extends StatelessWidget {
  PoehalisnamiApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PSN Hotels',
      initialRoute: '/',
      theme: ThemeData(useMaterial3: true, colorScheme: lightColorScheme, fontFamily: 'SFUIDisplay'),
      home: BlocConsumer(
        bloc: BlocProvider.of<FlowCubit>(context),
        builder: _builder,
        listenWhen: _listenWhen,
        listener: _listener,
      ),
    );
  }

  Widget _builder(context, state) {
    if (state == FlowState.Login) {
      return BlocProvider(
        create: (context) => SignInCubit(),
        child: SignInScreen(),
      );
    } else if (state == FlowState.Home) {
      return BlocProvider(
        create: (context) => MyHotelsCubit()..initial(query: BaseQuery()),
        child: MyHotelsScreen(),
      );
    } else if (state == FlowState.Onboarding) {
      return OnboardingScreen();
    } else {
      if (wasOfferToUpdate == false) {
        _checkUpdate(context);
      }
      return SplashScreen();
    }
  }

  bool _listenWhen(lastState, currentState) {
    if (lastState == currentState) {
      return false;
    }
    return true;
  }

  _listener(context, state) {
    if (state == FlowState.Home) {
      BlocProvider.of<HotelsDialogCubit>(context).initial(query: BaseQuery());
    }
    if (state == FlowState.Onboarding) {
      BlocProvider.of<HotelsDialogCubit>(context).initial(query: BaseQuery());
    }
  }
}

class MainBlocDelegate extends BlocObserver {
  @override
  void onEvent(Bloc bloc, Object? event) {
    print(event);
    super.onEvent(bloc, event);
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    print(change);
    super.onChange(bloc, change);
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    print(transition);
    super.onTransition(bloc, transition);
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    print(error);
    super.onError(bloc, error, stackTrace);
  }
}
