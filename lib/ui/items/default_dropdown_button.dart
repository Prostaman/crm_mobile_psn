import 'package:flutter/material.dart';
import 'package:psn.hotels.hub/helpers/ui_helper.dart';

class DefaultDropdownButtonModel {
  String title;
  String? id;
  bool isDefault;

  DefaultDropdownButtonModel(
      {required this.title, required this.id, required this.isDefault});
}

class DefaultDropdownButton extends StatefulWidget {
  final List<DefaultDropdownButtonModel>? models;
  final Function(DefaultDropdownButtonModel)? callback;
  final DefaultDropdownButtonModel? selected;

  DefaultDropdownButton({
    Key? key,
    required this.models,
    required this.callback,
    this.selected,
  })  : assert(models != null, callback != null),
        super(key: key);

  @override
  _DefaultDropdownButtonState createState() =>
      _DefaultDropdownButtonState(selected: this.selected);
}

class _DefaultDropdownButtonState extends State<DefaultDropdownButton> {
  DefaultDropdownButtonModel? selected;

  _DefaultDropdownButtonState({required this.selected});

  @override
  Widget build(BuildContext context) {
    if (selected == null && (widget.models?.length ?? 0) > 0) {
      selected = widget.models?.first;
    } else if (selected == null) {
      selected = DefaultDropdownButtonModel(
          title: "Не выбрано", id: null, isDefault: true);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 38,
          child: FormField<DefaultDropdownButtonModel>(
            initialValue: selected,
            builder: (FormFieldState<DefaultDropdownButtonModel> state) {
              return Container(
                decoration: BoxDecoration(
                    // color: Colors.grey[100],
                    // borderRadius: BorderRadius.circular(4),
                    // border: Border.all(
                    //   color: Colors.grey[200],
                    // ),
                    ),
                padding: const EdgeInsets.only(
                    left: 0, right: 0, top: 4.5, bottom: 4.5),
                child: DropdownButton<DefaultDropdownButtonModel>(
                  value: selected,
                  dropdownColor: Colors.grey[200],
                  style: textStyle(size: 15, color: ColorTextDefault, h: 1),
                  isDense: true,
                  onChanged: (DefaultDropdownButtonModel? newValue) {
                    setState(() {
                      if (newValue != null) {
                        selected = newValue;
                        widget.callback?.call(selected!);
                        state.didChange(selected);
                      }
                    });
                  },
                  items: widget.models
                      ?.map(
                        (e) => DropdownMenuItem<DefaultDropdownButtonModel>(
                          value: e,
                          child: Text(e.title),
                        ),
                      )
                      .toList(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
