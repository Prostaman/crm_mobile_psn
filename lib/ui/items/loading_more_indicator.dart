import 'package:flutter/material.dart';
import 'package:psn.hotels.hub/helpers/ui_helper.dart';

class LoadingMoreInsicator extends StatelessWidget {
  final Alignment alignment;
  const LoadingMoreInsicator({Key? key, required this.alignment}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Align(
        alignment: alignment,
        child: Container(
          margin: const EdgeInsets.all(10),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15.0), boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 5.0,
              offset: Offset(0.0, 0.0),
            ),
          ]),
          width: 40,
          height: 40,
          child: DefaultIndicator,
        ),
      ),
    );
  }
}
