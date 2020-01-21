import 'dart:collection';

import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:json_to_dart/src/string_utils.dart';

class DartClassBuilder {
  static const _imports = const [
    'package:json_annotation/json_annotation.dart',
    'package:meta/meta.dart',
  ];
  String buildDartFile(
      String fileNamePrefix, String rootClassName, dynamic data,
      {bool addDtoSuffix = true, Map<String, String> jsonKeyTranslations}) {
    Iterable<ClassMetadata> classes =
        MetadataBuilder(addDtoSuffix, jsonKeyTranslations)
            .buildMetadata(rootClassName, data)
            .toList()
            .reversed;
    final lib = Library((b) => b
      ..body.add(Code("part '$fileNamePrefix.g.dart';"))
      ..body.addAll(classes.map((c) => buildClass(c)).toList())
      ..directives.addAll(_imports.map((import) => Directive.import(import))));
    final emitter = DartEmitter();
    return DartFormatter().format('${lib.accept(emitter)}');
  }

  Field _buildField(FieldMetadata fieldMetadata) {
    final name = fieldMetadata.name;
    final jsonKey = fieldMetadata.jsonKey;
    return Field(
      (b) => b
        ..name = name
        ..type = refer(fieldMetadata.type)
        ..annotations.add(refer("JsonKey(name: '$jsonKey')"))
        ..modifier = FieldModifier.final$,
    );
  }

  Parameter toParam(FieldMetadata fieldMetadata, bool named) {
    return Parameter(
      (b) => b
        ..name = fieldMetadata.name
        ..toThis = true
        ..named = named,
    );
  }

  Constructor _buildConstructor(List<FieldMetadata> fields) {
    final isOptional = fields.length > 1;
    final params = fields.map((f) => toParam(f, isOptional)).toList();
    if (!isOptional) {
      return Constructor((b) => b
        ..requiredParameters.addAll(params)
        ..constant = true);
    } else {
      return Constructor((b) => b
        ..optionalParameters.addAll(params)
        ..constant = true);
    }
  }

  Class buildClass(ClassMetadata classMetadata) {
    return Class((b) {
      b
        ..annotations.addAll([
          refer('JsonSerializable(disallowUnrecognizedKeys: true)'),
          refer('immutable')
        ]);
      if (classMetadata.isRoot)
        b..fields.add(_createFromJsonFactoryStatic(classMetadata.name));

      b..constructors.add(_createFromJsonConstructor(classMetadata.name));
      b
        ..fields
            .addAll(classMetadata.fields.map((f) => _buildField(f)).toList())
        ..name = classMetadata.name
        ..constructors.add(_buildConstructor(classMetadata.fields));

      b..methods.add(_createToJsonMethod(classMetadata.name));
      return b;
    });
  }

  Field _createFromJsonFactoryStatic(String className) {
    return Field((b) => b
      ..name = "fromJsonFactory"
      ..static = true
      ..modifier = FieldModifier.constant
      ..assignment = Code('_\$${className}FromJson'));
  }

  Method _createToJsonMethod(String className) {
    return Method((b) => b
      ..returns = refer('Map<String, dynamic>')
      ..name = 'toJson'
      ..lambda = true
      ..body = Code('_\$${className}ToJson(this)'));
  }

  Constructor _createFromJsonConstructor(String className) {
    return Constructor((b) => b
      ..factory = true
      ..name = 'fromJson'
      ..requiredParameters.add(Parameter((p) => p
        ..name = 'json'
        ..type = refer('Map<String, dynamic>')))
      ..lambda = true
      ..body = Code('_\$${className}FromJson(json)'));
  }
/**
 *
 *  static const fromJsonFactory = _$CourseOrganizationsResponseFromJson;
 *   factory CourseOrganizationsDto.fromJson(Map<String, dynamic> json) =>
    _$CourseOrganizationsDtoFromJson(json);

    Map<String, dynamic> toJson() => _$CourseOrganizationsDtoToJson(this);
 */
}

class MetadataBuilder {
  final bool addDtoSuffix;
  final Map<String, String> jsonKeyTranslations;
  Set<ClassMetadata> outClassMetadataList = LinkedHashSet();

  MetadataBuilder(this.addDtoSuffix, this.jsonKeyTranslations);

  Set<ClassMetadata> buildMetadata(String rootClassName, dynamic data) {
    if (data is Map<String, dynamic>) {
      outClassMetadataList.clear();
      createClassMetaDatas(rootClassName, true, data);
      return outClassMetadataList;
    } else if (data is Iterable<dynamic>) {
      if (data.isEmpty) {
        throw Exception("not sure what to do with this: $data");
      } else {
        final first = data.first;
        return buildMetadata(rootClassName, first);
      }
    } else {
      throw Exception("not sure what to do with this: $data");
    }
  }

  void createClassMetaDatas(
      String className, bool isRoot, Map<String, dynamic> data) {
    outClassMetadataList.add(
        ClassMetadata(className, createFieldMetadataListFromMap(data), isRoot));
  }

  String translateKey(String key) {
    var result = (jsonKeyTranslations ?? {})[key] ?? key;
    if (_reservedKeywords.contains(result.toLowerCase())) result += "\$";
    return result;
  }

  String createClassName(String key) {
    return toTitleCase(key) + (addDtoSuffix ? "Dto" : "");
  }

  FieldMetadata createFieldMetadata(String k, dynamic v) {
    final name = translateKey(k);
    if (v is Map<String, dynamic>) {
      final className = createClassName(name);
      createClassMetaDatas(className, false, v);
      return FieldMetadata(k, toCamelCaseString(name), className);
    } else if (v is Iterable<dynamic>) {
      if (v.isEmpty) {
        final className = createClassName(name);
        outClassMetadataList.add(ClassMetadata(className, [], false));
        return FieldMetadata(
            k, toCamelCaseString(name), "Iterable<$className>");
      } else {
        final field = createFieldMetadata(k, v.first);
        return FieldMetadata(
            field.jsonKey, field.name, "Iterable<${field.type}>");
      }
    } else {
      return FieldMetadata(k, toCamelCaseString(name), toType(v));
    }
  }

  List<FieldMetadata> createFieldMetadataListFromMap(Map<String, dynamic> map) {
    return map.entries.map((entry) {
      final k = entry.key;
      final v = entry.value;
      return createFieldMetadata(k, v);
    }).toList(growable: false);
  }

  String toType(dynamic value) {
    return value.runtimeType.toString();
  }
}

class FieldMetadata {
  final String jsonKey;
  final String name;
  final String type;

  FieldMetadata(this.jsonKey, this.name, this.type);
}

class ClassMetadata {
  final String name;
  final List<FieldMetadata> fields;
  final bool isRoot;

  ClassMetadata(this.name, this.fields, this.isRoot);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClassMetadata &&
          runtimeType == other.runtimeType &&
          name == other.name;

  @override
  int get hashCode => name.hashCode;
}

const _reservedKeywords = ['class'];
