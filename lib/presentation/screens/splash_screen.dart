import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:psn.hotels.hub/presentation/blocks/splash/splash_cubit.dart';
import 'package:psn.hotels.hub/presentation/blocks/splash/splash_state.dart';
import 'package:psn.hotels.hub/infrastructure/images.gen.dart';
import 'package:psn.hotels.hub/presentation/ui_helper.dart';
import 'package:psn.hotels.hub/presentation/buttons/default_button.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    context.read<SplashCubit>().startLoading();
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
              child: BlocBuilder<SplashCubit, SplashState>(
                  builder: (context, state) {
                return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        state.message,
                        style: textStyle(size: 20),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 32),
                      state.error == false
                          ? CircularProgressIndicator()
                          : DefaultButton(
                              title: "Повторить",
                              textSize: 18,
                              scheme: DefaultButtonScheme.Orange,
                              onPressed: () {
                                context.read<SplashCubit>().startLoading();
                              },
                            ),
                    ]);
              }))
        ]),
      ),
    );
  }
}
