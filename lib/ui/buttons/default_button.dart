import 'package:flutter/material.dart';
import 'package:psn.hotels.hub/helpers/ui_helper.dart';

enum DefaultButtonScheme { Orange, White }

class DefaultButton extends StatelessWidget {
  final DefaultButtonScheme scheme;
  final VoidCallback onPressed;
  final String title;
  final Widget? titleIcon;
  final bool enable;
  final bool loading;
  final double rounded;
  final double height;
  final double textSize;

  const DefaultButton(
      {Key? key,
      required this.title,
      required this.scheme,
      required this.onPressed,
      this.enable = true,
      this.loading = false,
      this.rounded = 6,
      this.titleIcon,
      this.height = 44,
      this.textSize = 14})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color color = ColorRed;
    Color textColor = Colors.white;
    Color disableTextColor = Colors.white;
    Color indicatorValueColor = ColorOrange;
    Color indicatorBackgroundColor = Colors.white;
    Color borderColor = ColorRed;
    const String titleOfLoading = 'Идёт выгрузка';

    switch (scheme) {
      case DefaultButtonScheme.Orange:
        color = ColorOrange;
        textColor = ColorTextWhite;
        disableTextColor = ColorTextBlack;
        indicatorValueColor = ColorRed;
        indicatorBackgroundColor = ColorWhite;
        borderColor = ColorOrange;
        break;
      case DefaultButtonScheme.White:
        color = ColorWhite;
        textColor = Colors.black;
        disableTextColor = ColorTextBlue.withOpacity(0.6);
        indicatorValueColor = ColorRed;
        indicatorBackgroundColor = Colors.white;
        borderColor = Color.fromRGBO(108, 106, 106, 0.5);
        break;

      default:
    }
    return TextButton(
      style: TextButton.styleFrom(
        fixedSize: Size.fromHeight(height),
        shape: RoundedRectangleBorder(
          side: BorderSide(color: enable == true ? borderColor : borderColor.withOpacity(0.4)),
          borderRadius: BorderRadius.circular(this.rounded),
        ),
        backgroundColor: enable == true ? color : color.withOpacity(0.6),
      ),
      onPressed: (enable == true && loading == false) ? onPressed : null,
      child: loading == true
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(width: 24),
                if (titleIcon != null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        titleOfLoading,
                        textAlign: TextAlign.center,
                        style: textStyle(
                          weight: Regular4,
                          size: textSize,
                          color: enable == true ? textColor : disableTextColor,
                        ),
                      ),
                      SizedBox(width: 16),
                      titleIcon!
                    ],
                  )
                else
                  Expanded(
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(
                      titleOfLoading,
                      textAlign: TextAlign.center,
                      style: textStyle(
                        weight: Regular4,
                        size: textSize,
                        color: enable == true ? textColor : disableTextColor,
                      ),
                    ),
                    SizedBox(width: 16),
                    Container(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(indicatorValueColor),
                        backgroundColor: indicatorBackgroundColor,
                        strokeWidth: 3,
                      ),
                    )
                  ]))
              ],
            )
          : (titleIcon != null)
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: textStyle(
                        weight: Regular4,
                        size: textSize,
                        color: enable == true ? textColor : disableTextColor,
                      ),
                    ),
                    SizedBox(width: 16),
                    titleIcon!
                  ],
                )
              : Text(
                  title,
                  textAlign: TextAlign.center,
                  style: textStyle(
                    weight: Regular4,
                    size: textSize,
                    color: enable == true ? textColor : disableTextColor,
                  ),
                ),
    );
  }
}
