import 'package:flutter/material.dart';
import 'package:psn.hotels.hub/helpers/ui_helper.dart';
import 'package:psn.hotels.hub/ui/buttons/default_button.dart';
import 'package:psn.hotels.hub/ui/items/default_cupertino_text_field.dart';

class HotelDescriptionBottomSheet extends StatelessWidget {
  final Function(String?) saveCallback;
  final String? description;
  const HotelDescriptionBottomSheet({
    Key? key,
    required this.description,
    required this.saveCallback,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String? _description = description;
    return Padding(
        padding: EdgeInsets.only(left: 22, right: 22, bottom: MediaQuery.of(context).viewInsets.bottom + 22, top: 22),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(
            description == null ? "Добавить описание" : "Редактировать описание",
            style: textStyle(size: 22, weight: Medium5),
          ),
          SizedBox(height: 26),
          Container(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Container(
                    // constraints: BoxConstraints(
                    //   maxHeight: MediaQuery.of(context).size.height / 2,
                    //   minHeight: 100,
                    // ),
                    child: DefaultTextField(
                      onChanged: (newValue) {
                        _description = newValue;
                      },
                      initialText: _description,
                      maxLenght: 1000,
                      maxLines: 20,
                      // maxLines: 20,
                      minLines: 10,
                      placeholder: "",
                      alignLabelWithHint: true,
                    ),
                  ),
                ),
                SizedBox(
                  height: 26,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: DefaultButton(
                        title: "Отмена",
                        scheme: DefaultButtonScheme.White,
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    SizedBox(width: 26),
                    Expanded(
                      child: DefaultButton(
                        title: "Сохранить",
                        scheme: DefaultButtonScheme.Orange,
                        onPressed: () {
                          saveCallback(_description);
                          Navigator.pop(context);
                        },
                      ),
                    )
                  ],
                )
              ],
            ),
          ),
        ]));
  }
}
