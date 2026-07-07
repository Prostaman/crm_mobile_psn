import 'package:flutter/material.dart';

class LoadingIndicatorWidget extends StatelessWidget {
  const LoadingIndicatorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color.fromRGBO(0, 0, 0, 0.2),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: DefaultBigIndicator,
        ),
      ),
    );
  }
}

// ignore: non_constant_identifier_names
Widget DefaultBigIndicator = Container(
  padding: const EdgeInsets.all(16.0),
  decoration: BoxDecoration(
    color: Colors.black54,
    borderRadius: BorderRadius.all(const Radius.circular(8.0)),
    border: Border.all(
      color: Colors.white,
      width: 0.0,
    ),
  ),
  child: FittedBox(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 40.0,
          height: 40.0,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.black54),
            backgroundColor: Colors.white,
            strokeWidth: 3,
          ),
        ),
      ],
    ),
  ),
);
