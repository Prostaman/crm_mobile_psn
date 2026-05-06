import 'package:psn.hotels.hub/presentation/blocks/base_cubit/base_cubit.dart';
import 'package:psn.hotels.hub/data/models/response_models/user_model.dart';
import 'package:psn.hotels.hub/di/service_container.dart';

class AuthUserCubit extends BaseCubit {
  UserModel? user;

  AuthUserCubit() : super(SuccessModelState(model: null)) {
    // this.listen((state) {
    //   if (state is ErrorState) {
    //     showSnackBar(context: context, message: state.error);
    //   }
    // });
  }

  Future<void> changeUser(UserModel? model) async {
    this.user = model;

    emit(SuccessModelState(model: model));
  }

  Future<void> logout() async {
    try {
      await ServiceContainer().authService.logout();
    } catch (e) {
      catchError(e);
    }
  }
}
