import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:json_to_dart/src/dart_class_builder.dart';

import 'utils/resource_utils.dart';

void main() {
  test("convert json to dart", () {
    DartClassBuilder dartClassBuilder = DartClassBuilder();
    String inputJson = readResource("input.json");
    final dynamic data = jsonDecode(inputJson);
    final fileNamePrefix = "example_dto";
    final className = "ExampleResponse";
    final jsonKeyClassNameMap = {"Voorbeeld": "Example"};
    final outputContent = dartClassBuilder.buildDartFile(
        fileNamePrefix, className, data,
        jsonKeyTranslations: jsonKeyClassNameMap);
    writeResource("$fileNamePrefix.dart", outputContent);
  });
}
