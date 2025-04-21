import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:psn.hotels.hub/db/db_manager.dart';
import 'package:psn.hotels.hub/helpers/images.gen.dart';
import 'package:psn.hotels.hub/helpers/ui_helper.dart';
import 'package:psn.hotels.hub/repository/repository_container.dart';
import 'package:psn.hotels.hub/services/service_container.dart';
import 'package:psn.hotels.hub/ui/buttons/default_button.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  StreamSubscription? subscriptionLoadingHotels;
  StreamSubscription? subscriptionInsertingHotels;
  StreamSubscription? subscriptionInsertingCategories;
  bool error = false;

  String textMessage = 'Идет загрузка отелей. Это может занять несколько минут.';

  @override
  void initState() {
    super.initState();
    initSubscriptionLoadingHotels();
    initSubscriptionInsertingHotels();
    initSubscriptionLoadingCategories();
  }

  Future<void> initSubscriptionLoadingHotels() async {
    subscriptionLoadingHotels = RepositoryContainer().hotelListRepository.observerOfLoadingHotels.stream.listen((item) {
      setState(() {
        error = item;
        textMessage = 'Ошибка при скачивании отелей. Попробуйте повторить позже.';
      });
    });
  }

  Future<void> initSubscriptionInsertingHotels() async {
    subscriptionInsertingHotels = (await DBManager().hotelsDao()).observerOfInsertingHotels.stream.listen((loadedHotelsInProcent) {
      setState(() {
        textMessage = "Сохранено $loadedHotelsInProcent% отелей";
      });
    });
  }

  Future<void> initSubscriptionLoadingCategories() async {
    subscriptionInsertingCategories = RepositoryContainer().categoriesRepository.observerOfLoadingCategories.stream.listen((item) {
      setState(() {
        error = item;
        textMessage = 'Ошибка при скачивании категорий для локаций. Попробуйте повторить позже.';
      });
    });
  }

  @override
  void dispose() {
    subscriptionInsertingHotels?.cancel();
    subscriptionLoadingHotels?.cancel();
    subscriptionInsertingCategories?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorWhite,
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 56),
            child: SvgPicture.asset(IMG.icons.logoPNG, fit: BoxFit.scaleDown),
          ),
          SizedBox(height: 32),
          Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(
                  textMessage,
                  style: textStyle(size: 20),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 32),
                error == false
                    ? CircularProgressIndicator()
                    : DefaultButton(
                        title: "Повторить",
                        textSize: 18,
                        scheme: DefaultButtonScheme.Orange,
                        onPressed: () {
                          setState(() {
                            error = false;
                          });
                          ServiceContainer().authService.checkAutorization();
                        },
                      ),
              ]))
        ]),
      ),
    );
  }
}
