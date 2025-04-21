// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:flutter/material.dart';
// import 'package:psn.hotels.hub/helpers/ui_helper.dart';

// class IconWidget extends StatelessWidget {
//   final String? asset;
//   final String? url;
//   final double height;
//   final double? width;

//   const IconWidget({Key? key, this.asset, this.url, required this.height, this.width}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     if (asset != null) {
//       return Image.asset(
//         asset!,
//         height: height,
//         width: width,
//       );
//     } else if (url != null) {
//       return CachedNetworkImage(
//         imageUrl: url!,
//         height: height,
//         width: width,
//         fit: width != null ? BoxFit.cover : BoxFit.contain,
//         errorWidget: (s, t, i) {
//           return errorWidget;
//         },
//       );
//     } else {
//       return errorWidget;
//     }
//   }

//   Widget get errorWidget {
//     return Container(
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(6),
//         color: Colors.grey.withOpacity(0.4),
//       ),
//       width: width,
//       height: height,
//       child: Center(
//           child: Text(
//         "NO IMAGE",
//         style: textStyle(size: 12, weight: Semibold6),
//       )),
//     );
//   }
// }
