import 'package:intl/intl.dart';

enum DateFormatType {
  Date,
  Time,
  DateTime,
  Short,
  Medium,
  Full,
}

DateTime? stringToDate(String date, {String format = ""}) {
  if (format == "") {
    return DateTime.tryParse(date);
  }
  var outputFormat = DateFormat(format);
  return outputFormat.parse(date);
}

String formatDate(DateTime date, {DateFormatType format = DateFormatType.Medium}) {
  switch (format) {
    case DateFormatType.Date:
      return DateFormat('dd.MM.y').format(date.toLocal());
    case DateFormatType.Time:
      return DateFormat('hh:mm a').format(date.toLocal());
    case DateFormatType.DateTime:
      return DateFormat('dd.MM.y, hh:mm').format(date.toLocal());
    case DateFormatType.Short:
      return DateFormat('MMMM dd, hh:mm a').format(date.toLocal());
    case DateFormatType.Medium:
      return DateFormat('MMMM dd, y in hh:mm a').format(date.toLocal());
    case DateFormatType.Full:
      return DateFormat('MM.dd.yy, hh:mm a').format(date.toLocal());
    default:
      return DateFormat('mm.dd.yyyy hh.mm.ss').format(date.toLocal());
  }
}

int daysBetween(DateTime from, DateTime to) {
  from = DateTime(from.year, from.month, from.day);
  to = DateTime(to.year, to.month, to.day);
  return (to.difference(from).inHours / 24).round();
}

int hoursBetween(DateTime from, DateTime to) {
  from = DateTime(from.year, from.month, from.day, from.hour, from.minute);
  to = DateTime(to.year, to.month, to.day, from.hour, from.minute);
  return to.difference(from).inHours.round();
}

