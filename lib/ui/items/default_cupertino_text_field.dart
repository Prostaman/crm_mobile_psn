import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:psn.hotels.hub/helpers/ui_helper.dart';

class DefaultTextField extends StatefulWidget {
  final String? initialText;
  final String placeholder;
  final TextInputType keyboardType;
  final bool obscureText;
  final bool readOnly;
  final Function(String) onChanged;
  final int? maxLines;
  final int minLines;
  final bool alignLabelWithHint;
  final String? suffixIconPath;
  final String? Function(String?)? validator;
  final String? errorText;
  final int? maxLenght;
  final bool multiline;
  final List<TextInputFormatter>? inputFormatter;

  DefaultTextField({
    Key? key,
    this.initialText,
    this.obscureText = false,
    this.readOnly = false,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.minLines = 1,
    required this.onChanged,
    required this.placeholder,
    this.suffixIconPath,
    this.validator,
    this.errorText,
    this.alignLabelWithHint = false,
    this.maxLenght,
    this.multiline = false,
    this.inputFormatter,
  }) : super(key: key);

  @override
  _DefaultTextFieldState createState() => _DefaultTextFieldState();
}

class _DefaultTextFieldState extends State<DefaultTextField> {
  TextEditingController? _controller;
  bool _passwordVisible = false;

  bool _oldPasswordVisible = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      _controller = TextEditingController(text: widget.initialText);
    }

    if (_controller != null && _controller?.text != widget.initialText && _oldPasswordVisible == _passwordVisible) {
      _controller = TextEditingController(text: widget.initialText);
    }

    if (widget.readOnly == true) {
      _controller?.text = widget.initialText ?? "";
    }

    _oldPasswordVisible = _passwordVisible;

    Widget textField = TextFormField(
      maxLength: widget.maxLenght,
      controller: _controller,
      maxLines: (widget.maxLines ?? 1) > 1 ? null : widget.maxLines,
      minLines: widget.minLines,
      readOnly: widget.readOnly,
      enabled: !widget.readOnly,      
      obscureText: widget.obscureText == true ? !_passwordVisible : widget.obscureText,
      style: textStyle(size: 15, color: ColorTextBlack),
      keyboardType: (widget.maxLines ?? 1) > 1 ? TextInputType.multiline : widget.keyboardType,
      autofocus: false,
      validator: widget.validator,
      inputFormatters: widget.inputFormatter,
      decoration: InputDecoration(
        labelText: widget.placeholder,
        errorText: widget.errorText,
        alignLabelWithHint: widget.alignLabelWithHint,

        // filled: true,
        // isDense: true,

        fillColor: ColorWhite,
        focusColor: ColorWhite,
        hoverColor: ColorWhite,
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: ColorBorderV2),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: ColorBorderV2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: ColorBorderV2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: ColorRed),
        ),

        errorStyle: textStyle(color: ColorRed, size: 12),
        helperStyle: textStyle(color: Color.fromRGBO(160, 160, 160, 1), size: 12),
        suffixIcon: widget.suffixIconPath != null
            ? Container(
                width: 20,
                height: 20,
                child: Center(
                  child: Image.asset(
                    widget.suffixIconPath!,
                    width: 14,
                    height: 14,
                    fit: BoxFit.fill,
                  ),
                ))
            : widget.obscureText == true
                ? IconButton(
                    focusColor: ColorOrange,
                    hoverColor: ColorOrange,
                    splashColor: ColorOrange,
                    highlightColor: ColorOrange,
                    splashRadius: 18,
                    iconSize: 18,
                    icon: Icon(
                      _passwordVisible ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _passwordVisible = !_passwordVisible;
                      });
                    },
                  )
                : null,
      ),
      onChanged: widget.onChanged
    );

    return textField;
  }
}
