/*
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:psn.hotels.hub/blocks/base_cubit/base_cubit.dart';
import 'package:psn.hotels.hub/blocks/hotels/hotels_dialog_cubit.dart';
import 'package:psn.hotels.hub/helpers/ui_helper.dart';
import 'package:psn.hotels.hub/services/service_container.dart';
*/

/*
class RadiusTextField extends StatefulWidget {
  RadiusTextField({
    Key key,
  }) : super(key: key);

  @override
  _RadiusTextFieldState createState() => _RadiusTextFieldState();
}

class _RadiusTextFieldState extends State<RadiusTextField> {
  final _searchQuery = new TextEditingController();
  String _oldText = "";
  Timer _debounce;

  _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 1000),
      () {
        if (_oldText != _searchQuery.text) {
          _oldText = _searchQuery.text;

          int radius = int.tryParse(_oldText);
          if (radius != null) {
            if (radius <= 10000) {
              print("SAVE RADIUS - $radius");
              ServiceContainer().settingsService.saveFilterRadiusToShared(radius);
              BlocProvider.of<HotelsCubit>(context).initial(query: BaseQuery());
            }
          }
        }
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _searchQuery.addListener(_onSearchChanged);
    _searchQuery.text = ServiceContainer().settingsService.filterRadius?.toString();
  }

  @override
  void dispose() {
    _searchQuery.removeListener(_onSearchChanged);
    _searchQuery.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _searchQuery,
      maxLines: 1,
      minLines: 1,
      style: textStyle(size: 15, color: ColorTextBlack),
      keyboardType: TextInputType.numberWithOptions(signed: true, decimal: true),
      autofocus: false,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly, MetersFormatter()],
      decoration: InputDecoration(
        labelText: "Радиус поиска отелей (в метрах)",
        fillColor: ColorWhite,
        focusColor: ColorWhite,
        hoverColor: ColorWhite,
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: ColorGrey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: ColorGrey),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: ColorRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: ColorRed),
        ),
        errorStyle: textStyle(color: ColorRed, size: 12),
        helperStyle: textStyle(color: ColorGrey, size: 12),
      ),
    );
  }
}

class MetersFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    try {
      int v = int.tryParse(newValue.text);
      if (v <= 10000 && v > 0) {
        return newValue;
      } else if (v > 10000) {
        return TextEditingValue(text: "10000", selection: TextSelection(baseOffset: 5, extentOffset: 5));
      } else if (v <= 0) {
        return TextEditingValue(text: "1", selection: TextSelection(baseOffset: 1, extentOffset: 1));
      } else {
        return TextEditingValue(text: "1", selection: TextSelection(baseOffset: 1, extentOffset: 1));
      }
    } catch (e) {
      return oldValue;
    }
    // if ()

    //   final regEx = RegExp(r"^.{1,35}$");
    //   String newString = regEx.stringMatch(newValue.text) ?? "";
    //   return newString == newValue.text ? newValue : oldValue;
  }
}
*/