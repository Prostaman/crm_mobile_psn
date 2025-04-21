import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:psn.hotels.hub/helpers/ui_helper.dart';

class DefaultBorderedTextField extends StatefulWidget {
  final String text;
  final String placeholder;
  final String? suffixAsset;
  final TextInputType keyboardType;
  final bool obscureText;
  final bool readOnly;
  final Function(String) onChanged;
  final int maxLines;

  DefaultBorderedTextField({
    Key? key,
    this.text = "",
    this.placeholder = "",
    this.suffixAsset,
    this.obscureText = false,
    this.readOnly = false,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    required this.onChanged,
  }) : super(key: key);

  @override
  _DefaultBorderedTextFieldState createState() => _DefaultBorderedTextFieldState();
}

class _DefaultBorderedTextFieldState extends State<DefaultBorderedTextField> {
  TextEditingController? _controller;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      _controller = TextEditingController(text: widget.text);
    }
    if (widget.readOnly == true) {
      _controller!.text = widget.text;
    }

    return CupertinoTextField(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      controller: _controller,
      maxLines: widget.maxLines,
      readOnly: widget.readOnly,
      enabled: !widget.readOnly,
      placeholder: widget.placeholder,
      obscureText: widget.obscureText,
      placeholderStyle: textStyle(weight: Regular4, color: ColorTextDefault, size: 16, h: 1.2),
      keyboardType: TextInputType.emailAddress,
      decoration: BoxDecoration(
          color: CupertinoDynamicColor.withBrightness(
            color: CupertinoColors.white,
            darkColor: CupertinoColors.black,
          ),
          borderRadius: BorderRadius.all(Radius.circular(5.0)),
          border: Border.all(
            color: Colors.grey[300] ?? Color.fromARGB(255, 224, 224, 224),
          )),
      onChanged: widget.onChanged,
    );
  }
}
