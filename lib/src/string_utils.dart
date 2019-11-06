String toCamelCase(Iterable<String> parts) {
  if (parts.contains(null))
    throw Exception("calling toCamelCase with parts containing null");
  final keys = parts.toList();
  if (keys.isEmpty) throw Exception("calling toCamelCase with empty list");

  var firstPart = keys.first;
  var otherParts = keys.toList().sublist(1);
  return toCamelCaseString(
      firstPart + otherParts.map((s) => toTitleCase(s)).join());
}

String toCamelCaseString(String str) {
  return str[0].toLowerCase() + str.substring(1);
}

String toTitleCase(String str) => str[0].toUpperCase() + str.substring(1);

final _newLineRegex = RegExp(r'\r\n|\r|\n');

final _trailingNewLineRegex = RegExp(r'\r\n$|\r$|\n$');

bool containsNewLines(String str) {
  return _newLineRegex.hasMatch(str);
}

///removes trailing new lines
String removeNewLinesRight(String str) {
  return str.replaceAll(_trailingNewLineRegex, "");
}

String replaceNewLinesWith(String str, String replaceWith) {
  return str.replaceAll(_newLineRegex, replaceWith);
}
