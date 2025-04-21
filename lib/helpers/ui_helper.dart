import 'package:flutter/material.dart';

const ColorTextDefault = ColorTextBlack;
const SizeTextDefault = 16.0;
const WeightTextDefault = Regular4;
const ColorGreyV2 = Color.fromRGBO(108, 106, 106, 1);
const ColorTextOrange = const Color.fromRGBO(242, 99, 39, 1);
const ColorTextLightGrey = const Color.fromARGB(255, 164, 164, 164);
const ColorTextWhite = const Color.fromARGB(255, 255, 255, 255);
const ColorTextGrey = const Color.fromARGB(138, 0, 0, 0);
const ColorTextBlack = const Color.fromARGB(222, 0, 0, 0);
const ColorTextRed = const Color.fromARGB(255, 244, 67, 54);
const ColorTextBlue = const Color.fromARGB(255, 38, 82, 156);
const ColorTextBlackAlertDialog = const Color.fromRGBO(43, 54, 65, 1);

const ColorWhite = const Color.fromARGB(255, 255, 255, 255);
const ColorLight = const Color.fromARGB(255, 229, 229, 229);
const ColorOrange = const Color.fromRGBO(242, 99, 39, 1);
const ColorGrey = const Color.fromARGB(138, 0, 0, 0);
const ColorLightGrey = const Color.fromARGB(255, 224, 224, 224);
const ColorRed = const Color.fromARGB(255, 223, 74, 67);
const ColorGreen = const Color.fromARGB(255, 122, 195, 121);
const ColorBorder = const Color.fromARGB(255, 242, 241, 241);
const ColorBorderV2 = const Color.fromRGBO(234, 234, 234, 1);
const ColorDivider = const Color.fromARGB(255, 228, 230, 228);

Color colorOfUploading(double percentUploaded) {
  if (percentUploaded >= 70) {
    return Colors.green;
  } else if (percentUploaded >= 40) {
    return Colors.orange;
  } else {
    return Colors.red;
  }
}

const Thin1 = FontWeight.w100;
const Light3 = FontWeight.w300;
const Regular4 = FontWeight.w400;
const Medium5 = FontWeight.w500;
const Semibold6 = FontWeight.w600;
const Bold7 = FontWeight.w700;

textStyle({
  Color color = ColorTextDefault,
  num size = SizeTextDefault,
  FontWeight weight = WeightTextDefault,
  //String font = FontTextDefault,
  String font = 'SFUIDisplay',
  double h = 1.0,
  double sp = 0.2,
  TextDecoration? decoration,
}) {
  return TextStyle(
    fontFamily: font,
    fontWeight: weight,
    fontSize: size.toDouble(),
    color: color,
    height: h,
    letterSpacing: sp,
    decoration: decoration,
  );
}

showSnackBar({required BuildContext context, required String message, bool error = true}) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: Colors.transparent,
      behavior: SnackBarBehavior.floating,
      padding: const EdgeInsets.all(0),
      elevation: 0,
      content: Card(
        elevation: 4,
        child: ClipPath(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                left: BorderSide(color: error == true ? ColorRed : ColorGreen, width: 10),
              ),
            ),
            child: Text(
              message,
              style: textStyle(),
              maxLines: null,
            ),
          ),
          clipper: ShapeBorderClipper(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))),
        ),
      ),
    ),
  );
}

hideKeyboard({required BuildContext context}) {
  if (FocusScope.of(context).hasFocus) {
    FocusScope.of(context).unfocus();
  }
}

const DefaultIndicator = CircularProgressIndicator(
  valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
  backgroundColor: Colors.white,
  strokeWidth: 3,
);

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

// ignore: non_constant_identifier_names
Widget DefaultFullScreenIndicator = Container(
  color: Colors.black.withOpacity(0.2),
  child: Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: DefaultBigIndicator,
    ),
  ),
);
