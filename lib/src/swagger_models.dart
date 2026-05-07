class LinkDoc {
  const LinkDoc({
    required this.operationId,
    this.parameters = const {},
    this.description,
  });

  final String operationId;
  final Map<String, String> parameters;
  final String? description;
}

class ResponseDoc {
  const ResponseDoc(
    this.description, {
    this.schema,
    this.headersSchema,
    this.links,
  });

  final String description;

  final SchemaDoc? schema;
  final Map<String, dynamic>? headersSchema;
  final Map<String, LinkDoc>? links;
}

class SchemaDoc {
  const SchemaDoc(this.name, this.schema);

  /// The name of the schema.
  final String name;

  /// The schema definition in JSON map format.
  final Map<String, dynamic> schema;
}

enum ParamStyle { form, simple, matrix }

enum ParamLocation { header, query }

sealed class ParamDoc<T extends Object> {
  const ParamDoc({
    required this.name,
    required this.location,
    required this.description,
    this.required = false,
    this.deprecated = false,
    this.allowEmptyValue = false,
    this.explode,
    this.style,
    this.example,
  });

  final String name;
  final ParamLocation location;
  final String description;

  /// OpenAPI flags
  final bool required;
  final bool deprecated;
  final bool allowEmptyValue;
  final ParamStyle? style;
  final bool? explode;

  final T? example;

  SchemaDoc get schemaDoc;

  Map<String, dynamic> toOpenApi() => {
    'name': name,
    'in': location.name,
    'description': description,
    'required': required,
    'deprecated': deprecated,
    if (allowEmptyValue) 'allowEmptyValue': true,
    if (explode != null) 'explode': explode,
    'schema': schemaDoc.schema,
    if (example != null) 'example': example,
  };
}

class ParamDocString extends ParamDoc<String> {
  const ParamDocString({
    required super.name,
    required super.location,
    required super.description,
    super.example,
    super.required,
    this.minLength,
    this.maxLength,
    this.pattern,
    this.nullable = false,
    this.defaultValue,
  });

  final int? minLength;
  final int? maxLength;
  final String? pattern;
  final bool nullable;
  final String? defaultValue;

  @override
  SchemaDoc get schemaDoc => SchemaDoc(name, {
    'type': 'string',
    if (minLength != null) 'minLength': minLength,
    if (maxLength != null) 'maxLength': maxLength,
    if (pattern != null) 'pattern': pattern,
    if (nullable) 'nullable': true,
    if (defaultValue != null) 'default': defaultValue,
  });
}

class ParamDocNumber extends ParamDoc<num> {
  const ParamDocNumber({
    required super.name,
    required super.location,
    required super.description,
    super.example,
    super.required,
    this.minimum,
    this.maximum,
    this.nullable = false,
    this.defaultValue,
  });

  final num? minimum;
  final num? maximum;
  final bool nullable;
  final num? defaultValue;

  @override
  SchemaDoc get schemaDoc => SchemaDoc(name, {
    'type': 'number',
    if (minimum != null) 'minimum': minimum,
    if (maximum != null) 'maximum': maximum,
    if (nullable) 'nullable': true,
    if (defaultValue != null) 'default': defaultValue,
  });
}

class ParamDocBoolean extends ParamDoc<bool> {
  const ParamDocBoolean({
    required super.name,
    required super.location,
    required super.description,
    super.example,
    super.required,
    this.defaultValue,
  });

  final bool? defaultValue;

  @override
  SchemaDoc get schemaDoc => SchemaDoc(name, {
    'type': 'boolean',
    if (defaultValue != null) 'default': defaultValue,
  });
}

/// only for swag documentation
mixin SwaggerInfo {
  String get description;
  String? get descriptionBody => null;

  bool get requiresAuth => false;
  Map<int, ResponseDoc> get responses;
  List<SchemaDoc> get dependentSchemas => [];
  Map<String, dynamic>? get requestBodySchema => null;
  List<ParamDoc> get parameters => const [];
}
