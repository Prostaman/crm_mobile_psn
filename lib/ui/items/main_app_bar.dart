import 'package:flutter/material.dart';
import 'package:psn.hotels.hub/helpers/ui_helper.dart';

const double kToolbarHeight = 56.0;

class MainAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final double? bottomPreferredSize;
  final bool backButtonDisable;
  final VoidCallback? backButtonTapped;
  final double elevation;
  final Color backgroundColor;
  final List<Widget>? rightButtons;
  final String? centerTitle;

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + (bottomPreferredSize ?? 0.0));

  MainAppBar({
    Key? key,
    this.title = "Назад",
    this.bottomPreferredSize,
    this.backButtonTapped,
    this.backButtonDisable = false,
    this.elevation = 0,
    this.backgroundColor = Colors.transparent,
    this.rightButtons,
    this.centerTitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leadingWidth: title.length == 0 ? 60 : 86,
      leading: backButtonDisable == false
          ? InkWell(
              onTap: () => backButtonTapped != null ? backButtonTapped!() : Navigator.pop(context),
              child: Row(
                children: [
                  SizedBox(width: 8),
                  Icon(
                    Icons.arrow_back_ios,
                    color: Colors.black,
                  ),
                  Text(
                    title,
                    style: textStyle(size: 16, color: Colors.black),
                    textAlign: TextAlign.left,
                  ),
                ],
              ),
            )

          // TextButton.icon(
          //     onPressed: () => backButtonTapped != null ? backButtonTapped() : Navigator.pop(context),
          //     icon: new Icon(
          //       Icons.arrow_back_ios,
          //       color: Colors.black,
          //     ),
          //     label: Text(
          //       title,
          //       style: textStyle(size: 16, color: Colors.black),
          //       textAlign: TextAlign.center,
          //     ),
          //   )
          : null,
      title: centerTitle != null
          ? Text(
              centerTitle!,
              style: textStyle(size: 16, color: Colors.black, weight: Semibold6),
            )
          : null,
      backgroundColor: backgroundColor,
      elevation: elevation,
      actions: rightButtons != null ? rightButtons : [],
    );
  }
}
