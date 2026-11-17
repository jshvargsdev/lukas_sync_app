import 'package:intl/intl.dart';

/// Texto corto de antigüedad: "hace un momento", "hace 5 min", "hace 3 h",
/// y a partir de un día, la fecha: "15 nov, 9:30 a. m.".
String formatAge(DateTime at, {required DateTime now}) {
  final diff = now.difference(at);
  if (diff.isNegative || diff.inMinutes < 1) return 'hace un momento';
  if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'hace ${diff.inHours} h';
  return formatDateTime(at);
}

/// "17 nov, 9:30 a. m."
String formatDateTime(DateTime at) =>
    DateFormat('d MMM, h:mm a', 'es_VE').format(at);
