import 'package:bloc/bloc.dart';
import 'package:psn.hotels.hub/services/service_container.dart';

enum FlowState {
  Initial,
  Loading,
  Onboarding,
  Login,
  Home,
}

class FlowCubit extends Cubit<FlowState> {
  FlowCubit() : super(FlowState.Loading);

  Future<void> check() async {
    emit(FlowState.Loading);
    await ServiceContainer().authService.checkAutorization();
  }

  Future<void> login() async {
    emit(FlowState.Login);
  }

  Future<void> loading() async {
    emit(FlowState.Loading);
  }



  Future<void> onboarding() async {
    emit(FlowState.Onboarding);
  }

  Future<void> home() async {
    emit(FlowState.Home);
  }
}
