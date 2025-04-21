import 'package:flutter/material.dart';

pushTo({required Widget screen, String? name, required BuildContext context}) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (c) => screen,
      settings: RouteSettings(
        name: name != null ? name : screen.toStringShort(),
      ),
    ),
  );
}

pushTReplacement({required Widget screen, required BuildContext context}) {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (c) => screen
    ),
  );
}

MaterialPageRoute route({required Widget widget}) {
  return MaterialPageRoute(builder: (context) => widget);
}
