import 'package:psn.hotels.hub/infrastructure/settings_service.dart';
import 'package:psn.hotels.hub/data/services/synchronization_service.dart';

import '../data/services/auth_service.dart';

class ServiceContainer {
  static ServiceContainer _singleton = ServiceContainer._internal();

  factory ServiceContainer() {
    return _singleton;
  }

  static set instance(ServiceContainer instance) => _singleton = instance;

  AuthService get authService {
    return _authService;
  }

  SettingsService get settingsService {
    return _settingsService;
  }

  SinkService get sinkService {
    return _sinkService;
  }

  late AuthService _authService;
  late SettingsService _settingsService;
  late SinkService _sinkService;

  ServiceContainer._internal() {
    _authService = AuthService();
    _settingsService = SettingsService();
    _sinkService = SinkService();
  }
}
