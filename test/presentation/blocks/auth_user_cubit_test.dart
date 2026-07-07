import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:psn.hotels.hub/data/services/auth_service.dart';
import 'package:psn.hotels.hub/di/service_container.dart';
import 'package:psn.hotels.hub/presentation/blocks/auth_user_cubit/auth_user_cubit.dart';
import 'package:psn.hotels.hub/data/models/response_models/user_model.dart';
import 'package:psn.hotels.hub/presentation/blocks/base_cubit/base_cubit.dart';

class MockAuthService extends Mock implements AuthService {}

class MockServiceContainer extends Mock implements ServiceContainer {}

void main() {
  late AuthUserCubit authUserCubit;
  late MockAuthService mockAuthService;
  late MockServiceContainer mockServiceContainer;

  setUp(() {
    mockAuthService = MockAuthService();
    mockServiceContainer = MockServiceContainer();

    // Переопределяем ServiceContainer для тестов
    when(() => mockServiceContainer.authService).thenReturn(mockAuthService);
    ServiceContainer.instance = mockServiceContainer;

    authUserCubit = AuthUserCubit();
  });

  group('AuthUserCubit Tests', () {
    test(
        'Начальное состояние должно быть SuccessModelState с null пользователем',
        () {
      expect(authUserCubit.state, isA<SuccessModelState<UserModel?>>());
      expect(authUserCubit.user, isNull);
    });

    test('changeUser должен обновлять пользователя и эмитить SuccessModelState',
        () async {
      final user = UserModel(token: 'test_token');

      await authUserCubit.changeUser(user);

      expect(authUserCubit.user, user);
      expect(authUserCubit.state, isA<SuccessModelState<UserModel?>>());
      final state = authUserCubit.state as SuccessModelState<UserModel?>;
      expect(state.model, user);
    });

    test('logout должен вызывать authService.logout', () async {
      when(() => mockAuthService.logout()).thenAnswer((_) async => {});

      await authUserCubit.logout();

      verify(() => mockAuthService.logout()).called(1);
    });

    test(
        'logout должен обрабатывать ошибки через catchError (имитация ErrorState)',
        () async {
      final exception = Exception('Logout failed');
      when(() => mockAuthService.logout()).thenThrow(exception);

      // В BaseCubit catchError эмитит ErrorState
      await authUserCubit.logout();

      expect(authUserCubit.state, isA<ErrorState>());
    });
  });
}
