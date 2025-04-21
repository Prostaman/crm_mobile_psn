import 'dart:async';

import 'package:flutter/material.dart';
import 'package:psn.hotels.hub/helpers/ui_helper.dart';

class SearchFieldBox extends StatefulWidget {
  // final UsersBloc bloc;
  final Function(String) callback;
  final String placeholder;
  final Color? color;
  SearchFieldBox({Key? key, required this.placeholder, required this.callback, this.color}) : super(key: key);

  @override
  _SearchFieldBoxState createState() => _SearchFieldBoxState();
}

class _SearchFieldBoxState extends State<SearchFieldBox> {
  final _searchQuery = new TextEditingController();
  String _oldText = "";
  Timer? _debounce;

  _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (_oldText != _searchQuery.text) {
        widget.callback(_searchQuery.text);
        _oldText = _searchQuery.text;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _searchQuery.addListener(_onSearchChanged);
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
    Color color = Color.fromRGBO(108, 106, 106, 0.05);
    // Color color = ColorWhite;
    // if (widget.color != null) {
    //   color = widget.color!;
    // }
    return Container(
      padding: const EdgeInsets.all(0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: color,
        // border: Border.all(color: Colors.grey[200] ?? Color.fromARGB(255, 238, 238, 238)),
      ),
      child: 
      TextField(
        controller: _searchQuery,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 9),
          isDense: true,
          prefixIconConstraints: BoxConstraints(minWidth: 30, maxWidth: 30),
          prefixIcon: Icon(
            Icons.search,
            color: ColorTextLightGrey,
            size: 18,
          ),
          hintText: widget.placeholder,
          border: InputBorder.none,
          hintStyle: TextStyle(color: Colors.grey),
          suffixIconConstraints: BoxConstraints(maxHeight: 30, maxWidth: 30),
          suffixIcon: (_searchQuery.text.isNotEmpty)
              ? IconButton(
                  splashRadius: 30,
                  splashColor: Colors.transparent,
                  iconSize: 18,
                  color: Colors.grey,
                  onPressed: () {
                    setState(() {
                      _searchQuery.clear();
                    });
                  },
                  icon: Icon(Icons.clear),
                  alignment: Alignment.centerRight,
                )
              : null,
        ),
        style: textStyle(color: Colors.black, size: 19),
      ),
    )
    ;
  }
}
