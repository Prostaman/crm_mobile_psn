import 'package:geolocator/geolocator.dart';

class LocationHelper {
  static Position _position = Position(
    latitude: 50.450001,
    longitude: 30.523333,
    timestamp: DateTime.now(),
    accuracy: 10.0,
    altitude: 100.0,
    altitudeAccuracy: 5.0,
    heading: 90.0,
    headingAccuracy: 2.0,
    speed: 20.0,
    speedAccuracy: 1.5,
  );
  static Future init() async {
    await _getLocation();
  }

  static Future<void> _getLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      _position = position;
      Future.delayed(Duration(minutes: 1), () async {
        await _getLocation();
      });
    } catch (e) {
      Future.delayed(Duration(minutes: 1), () async {
        try {
          Position? lastKnown = await Geolocator.getLastKnownPosition();
          if (lastKnown != null) {
            _position = lastKnown;
          }
        } catch (ex) {
          // do nothing
        }

        await _getLocation();
      });
    }
  }

  static Position? getCurrentPosition() {
    return _position;
  }
}
