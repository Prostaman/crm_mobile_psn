import 'package:flutter/material.dart';
import 'package:psn.hotels.hub/helpers/ui_helper.dart';

class IndicatorOfUploading extends StatelessWidget {
  final double percentUploaded;
  const IndicatorOfUploading({Key? key, required this.percentUploaded}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            "${percentUploaded.toStringAsFixed(0)}%",
            style: TextStyle(fontSize: 14, color: colorOfUploading(percentUploaded)),
          ),
          Text(" загружено")
        ]),
        SizedBox(height: 7),
        Container(
          //width: 159,
          height: 5,
          child: ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(10)),
            child: LinearProgressIndicator(
              value: percentUploaded / 100,
              color: colorOfUploading(percentUploaded),
              backgroundColor: Color.fromRGBO(108, 106, 106, 0.08),
            ),
          ),
        )
      ],
    );
  }
}
