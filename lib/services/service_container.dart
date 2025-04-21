import 'package:psn.hotels.hub/services/auth_service.dart';
import 'package:psn.hotels.hub/services/settings_service.dart';
import 'package:psn.hotels.hub/services/sink_service.dart';
class ServiceContainer {
  static final ServiceContainer _singleton = ServiceContainer._internal();

  factory ServiceContainer() {
    return _singleton;
  }

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
