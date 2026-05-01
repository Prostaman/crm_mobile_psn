import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../../helpers/images.gen.dart';
import '../../../../ui_helper.dart';

class EmptySearchPlug extends StatelessWidget {
  final String text;

  const EmptySearchPlug({
    Key? key,
    this.text = "Отели не найдены",
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SvgPicture.asset(
          IMG.icons.hotelListEmptyPNG,
          width: 60,
          height: 60,
          fit: BoxFit.scaleDown,
        ),
        const SizedBox(height: 8),
        Text(
          text,
          style: textStyle(size: 16),
          textAlign: TextAlign.center,
        )
      ],
    );
  }
}
