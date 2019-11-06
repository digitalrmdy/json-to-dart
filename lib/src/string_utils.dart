String toCamelCaseString(String str) {
  return str[0].toLowerCase() + str.substring(1);
}

String toTitleCase(String str) => str[0].toUpperCase() + str.substring(1);
