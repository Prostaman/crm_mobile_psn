import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:psn.hotels.hub/data/services/auth_service.dart';
import 'package:psn.hotels.hub/di/service_container.dart';
import 'package:psn.hotels.hub/presentation/blocks/flow_cubit/flow_cubit.dart';

class MockAuthService extends Mock implements AuthService {}

class MockServiceContainer extends Mock implements ServiceContainer {}

void main() {
  late FlowCubit flowCubit;
  late MockAuthService mockAuthService;
  late MockServiceContainer mockServiceContainer;

  setUp(() {
    mockAuthService = MockAuthService();
    mockServiceContainer = MockServiceContainer();

    when(() => mockServiceContainer.authService).thenReturn(mockAuthService);
    ServiceContainer.instance = mockServiceContainer;

    flowCubit = FlowCubit();
  });

  group('FlowCubit Tests', () {
    test('Начальное состояние должно быть FlowState.Loading', () {
      expect(flowCubit.state, FlowState.Loading);
    });

    test('check() должен вызывать authService.checkAutorization', () async {
      when(() => mockAuthService.checkAutorization())
          .thenAnswer((_) async => {});

      await flowCubit.check();

      verify(() => mockAuthService.checkAutorization()).called(1);
    });

    test('login() должен переводить в FlowState.Login', () async {
      await flowCubit.login();
      expect(flowCubit.state, FlowState.Login);
    });

    test('home() должен переводить в FlowState.Home', () async {
      await flowCubit.home();
      expect(flowCubit.state, FlowState.Home);
    });

    test('onboarding() должен переводить в FlowState.Onboarding', () async {
      await flowCubit.onboarding();
      expect(flowCubit.state, FlowState.Onboarding);
    });
  });
}
