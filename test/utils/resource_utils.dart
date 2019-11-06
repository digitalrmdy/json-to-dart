import 'dart:io';

String readResource(String fileName) {
  String filePath = "test/resources/$fileName";
  String jsonString;
  try {
    jsonString = File(filePath).readAsStringSync();
  } catch (e) {
    jsonString = File("../" + filePath).readAsStringSync();
  }
  return jsonString;
}

void writeResource(String fileName, String contents) {
  String filePath = "test/resources/$fileName";
  File(filePath).writeAsStringSync(contents);
}
