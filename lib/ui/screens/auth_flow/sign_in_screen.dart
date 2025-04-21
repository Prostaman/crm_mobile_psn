import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:psn.hotels.hub/blocks/authentication/sign_in_cubit.dart';
import 'package:psn.hotels.hub/blocks/base_cubit/base_cubit.dart';
import 'package:psn.hotels.hub/helpers/images.gen.dart';
import 'package:psn.hotels.hub/ui/buttons/default_button.dart';
import 'package:psn.hotels.hub/helpers/ui_helper.dart';
import 'package:psn.hotels.hub/ui/items/default_cupertino_text_field.dart';
import 'package:psn.hotels.hub/ui/screens/base_screen.dart';

class SignInScreen extends StatefulWidget {
  SignInScreen({Key? key}) : super(key: key);

  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool showError = false;
  String? textError = "";
  SignInCubit get _cubit {
    return BlocProvider.of<SignInCubit>(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorWhite,
      resizeToAvoidBottomInset: true,
      body: _buildBody(),
    );
  }

  _buildBody() {
    return BlocConsumer(
      bloc: _cubit,
      listener: (context, state) {
        if (state is ErrorState) {
          //showSnackBar(context: context, message: state.error ?? "Empty");
          showError = true;
          textError = state.error;
        }
        if (state is SuccessModelState) {
          _cubit.auth.checkAutorization();
        }
      },
      builder: (context, state) {
        return BaseScreen(
          state: state as BaseCubitState,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SafeArea(child: SizedBox(height: 44)),
                  Center(
                    child: Container(
                      width: 289,
                      height: 119,
                      child: SvgPicture.asset(IMG.icons.logoPNG, fit: BoxFit.scaleDown),
                    ),
                  ),
                  SizedBox(height: 66),
                  Text(
                    "Добро пожаловать!",
                    style: textStyle(
                      size: 25,
                      color: ColorTextOrange,
                      weight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.left,
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Заполните поля для входа в систему",
                    style: textStyle(size: 16, color: Colors.black),
                    textAlign: TextAlign.left,
                  ),
                  SizedBox(height: 46),
                  DefaultTextField(
                    key: Key('usernameField'),
                    initialText: _cubit.signInRequest.login,
                    placeholder: "Логин",
                    keyboardType: TextInputType.text,
                    onChanged: (newValue) {
                      _cubit.signInRequest.login = newValue;
                    },
                    validator: (value) {
                      return state is ErrorState ? 'Неверный логин' : null;
                    },
                  ),
                  SizedBox(height: 16),
                  DefaultTextField(
                    key: Key('passwordField'),
                    initialText: _cubit.signInRequest.password,
                    placeholder: "Пароль",
                    obscureText: true,
                    keyboardType: TextInputType.visiblePassword,
                    onChanged: (newValue) {
                      _cubit.signInRequest.password = newValue;
                    },
                    validator: (value) {
                      return state is ErrorState ? 'Неверный пароль' : null;
                    },
                  ),
                  SizedBox(height: 14),
                  showError
                      ? Container(
                          height: 48,
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Color.fromRGBO(237, 57, 57, 0.04),
                          ),
                          child: SingleChildScrollView(
                              // Adding SingleChildScrollView here
                              scrollDirection: Axis.vertical, // Allowing horizontal scrolling
                              child: Padding(
                                  padding: EdgeInsets.only(top: 12),
                                  child: Row(
                                    children: [
                                      SvgPicture.asset(IMG.icons.iconWarning, fit: BoxFit.scaleDown),
                                      SizedBox(width: 8),
                                      Expanded(
                                          child: Text(
                                        "${textError ?? ""}",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Color.fromRGBO(255, 41, 41, 1),
                                        ),
                                      ))
                                    ],
                                  ))))
                      : SizedBox(height: 48),
                  SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: DefaultButton(
                          key: Key('loginButton'),
                          title: "Войти в систему",
                          rounded: 10,
                          textSize: 18,
                          height: 55,
                          scheme: DefaultButtonScheme.Orange,
                          onPressed: () {
                            showError = false;
                            _cubit.signIn();
                          },
                        ),
                      )
                    ],
                  ),
                  SafeArea(
                    child: Container(
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: "Для получения доступа, обратитесь на Email: ",
                              style: textStyle(size: 16, color: Colors.black),
                            ),
                            TextSpan(
                              text: "info@poehalisnami.com",
                              style: textStyle(
                                size: 16,
                                color: ColorOrange,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () async {
                                  Clipboard.setData(ClipboardData(text: "info@poehalisnami.com"));
                                  showSnackBar(
                                    context: context,
                                    message: "email скопирован в буфер обмена",
                                    error: false,
                                  );
                                },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 44),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
