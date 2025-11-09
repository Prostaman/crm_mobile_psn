import 'package:flutter/material.dart';

extension HexColor on Color {
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
  //old code
  // String toHex({bool leadingHashSign = true}) => '${leadingHashSign ? '#' : ''}'
  //     '${alpha.toRadixString(16).padLeft(2, '0')}'
  //     '${red.toRadixString(16).padLeft(2, '0')}'
  //     '${green.toRadixString(16).padLeft(2, '0')}'
  //     '${blue.toRadixString(16).padLeft(2, '0')}';

  /// Returns the color as a hex string in the form AARRGGBB.
  ///
  /// By default the returned string includes a leading `#`. Set [leadingHashSign]
  /// to `false` to omit it. Use [upperCase] to return uppercase hex digits.
  String toHex({bool leadingHashSign = true, bool upperCase = false}) {
    // Use component accessors (a, r, g, b) instead of deprecated members.
    // New component accessors may return double; convert to int first.
    final aHex = a.round().toRadixString(16).padLeft(2, '0');
    final rHex = r.round().toRadixString(16).padLeft(2, '0');
    final gHex = g.round().toRadixString(16).padLeft(2, '0');
    final bHex = b.round().toRadixString(16).padLeft(2, '0');
    final result = '${leadingHashSign ? '#' : ''}' + '$aHex$rHex$gHex$bHex';
    return upperCase ? result.toUpperCase() : result;
  }
}
