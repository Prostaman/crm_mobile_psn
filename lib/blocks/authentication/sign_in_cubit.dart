import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:psn.hotels.hub/blocks/base_cubit/base_cubit.dart';
import 'package:psn.hotels.hub/models/request_models/sign_in_request.dart';

class SignInCubit extends BaseCubit {
  SignInRequest signInRequest = SignInRequest();

  SignInCubit() : super(InitialState());

  Future<void> signIn() async {
    try {
      emit(LoadingState());

      debugPrint("cheking intertnet");
      var typeOfConnectionWithInternet =
          await (Connectivity().checkConnectivity());
      if (typeOfConnectionWithInternet == ConnectivityResult.none) {
        emit(ErrorState(error: "Проверьте интернет соеденение"));
        return;
      }

      if (!(signInRequest.login.isNotEmpty) &&
          !(signInRequest.password.isNotEmpty)) {
        emit(ErrorState(error: "Поля логин и пароль обязательны к заполнению"));
        return;
      }

      if (!(signInRequest.login.isNotEmpty)) {
        emit(ErrorState(error: "Поле логин обязательно к заполнению"));
        return;
      }

      if (!(signInRequest.password.isNotEmpty)) {
        emit(ErrorState(error: "Поле пароль обязательно к заполнению"));
        return;
      }

      var user = await auth.login(signInRequest);
      emit(SuccessModelState(model: user));
    } catch (e) {
      catchError(e);
    }
  }
}
