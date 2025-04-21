import 'package:flutter/material.dart';
import 'package:psn.hotels.hub/ui/buttons/default_button.dart';
import 'package:psn.hotels.hub/helpers/ui_helper.dart';

class PaginationListPlug extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;
  const PaginationListPlug({
    Key? key,
    required this.title,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: textStyle(),
          ),
          SizedBox(height: 20),
          if (onTap != null)
            DefaultButton(
              title: "Перезагрузить",
              scheme: DefaultButtonScheme.Orange,
              onPressed: onTap!,
            )
        ],
      ),
    );
  }
}
