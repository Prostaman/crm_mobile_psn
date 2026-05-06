import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:psn.hotels.hub/presentation/blocks/splash/splash_state.dart';
import 'package:psn.hotels.hub/data/datasources/local/db/db_manager.dart';
import 'package:psn.hotels.hub/data/repository/repository_container.dart';
import 'package:psn.hotels.hub/domain/services/service_container.dart';

class SplashCubit extends Cubit<SplashState> {
  SplashCubit() : super(SplashState(message: 'Идет загрузка отелей...'));

  StreamSubscription? subscriptionLoadingHotels;
  StreamSubscription? subscriptionInsertingHotels;
  StreamSubscription? subscriptionLoadingCategories;

  void setError(String message) {
    cancelSubscriptions();
    emit(state.copyWith(error: true, message: message));
  }

  void setProgress(int percent) => emit(
      state.copyWith(progress: percent, message: 'Сохранено $percent% отелей'));
  void resetError() =>
      emit(state.copyWith(error: false, message: 'Идет загрузка отелей...'));

  void startLoading() {
    // Підписки на стріми репозиторіїв
    resetError();
    ServiceContainer().authService.checkAutorization();
    //initSubscriptionLoadingHotels
    subscriptionLoadingHotels = RepositoryContainer()
        .hotelListRepository
        .observerOfLoadingHotels
        .stream
        .listen((hasError) {
      if (hasError)
        setError('Ошибка при скачивании отелей. Попробуйте повторить позже.');
    });

    DBManager().hotelsDao().then((dao) {
      subscriptionInsertingHotels =
          dao.observerOfInsertingHotels.stream.listen((progress) {
        setProgress(progress);
      });
    });

    subscriptionLoadingCategories = RepositoryContainer()
        .categoriesRepository
        .observerOfLoadingCategories
        .stream
        .listen((hasError) {
      if (hasError)
        setError(
            'Ошибка при скачивании категорий для локаций. Попробуйте повторить позже.');
    });
  }

  @override
  Future<void> close() {
    cancelSubscriptions();
    return super.close();
  }

  void cancelSubscriptions() {
    subscriptionInsertingHotels?.cancel();
    subscriptionLoadingHotels?.cancel();
    subscriptionLoadingCategories?.cancel();
  }
}
