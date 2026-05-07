import 'package:coouter/src/swagger_models.dart';
import 'package:test/test.dart';

void main() {
  group('LinkDoc', () {
    test('constructor assigns all properties', () {
      const link = LinkDoc(
        operationId: 'getUser',
        parameters: {'id': '123'},
        description: 'Get user by ID',
      );
      expect(link.operationId, 'getUser');
      expect(link.parameters, {'id': '123'});
      expect(link.description, 'Get user by ID');
    });

    test('description can be null', () {
      const link = LinkDoc(operationId: 'getUser');
      expect(link.description, isNull);
      expect(link.parameters, isEmpty);
    });
  });

  group('ResponseDoc', () {
    test('constructor assigns description', () {
      const doc = ResponseDoc('Success');
      expect(doc.description, 'Success');
      expect(doc.schema, isNull);
      expect(doc.headersSchema, isNull);
      expect(doc.links, isNull);
    });

    test('can include schema', () {
      const schema = SchemaDoc('User', {'type': 'object'});
      const doc = ResponseDoc('Success', schema: schema);
      expect(doc.schema?.name, 'User');
      expect(doc.schema?.schema, {'type': 'object'});
    });

    test('can include headersSchema', () {
      final doc = ResponseDoc(
        'Created',
        headersSchema: {
          'properties': {
            'X-Rate-Limit': {'type': 'integer'},
          },
        },
      );
      expect(doc.headersSchema, isNotNull);
    });

    test('can include links', () {
      const link = LinkDoc(operationId: 'getUser');
      final doc = ResponseDoc('Success', links: {'user': link});
      expect(doc.links, containsPair('user', link));
    });
  });

  group('SchemaDoc', () {
    test('constructor assigns name and schema', () {
      const schema = SchemaDoc('Error', {'type': 'object'});
      expect(schema.name, 'Error');
      expect(schema.schema, {'type': 'object'});
    });
  });

  group('ParamStyle', () {
    test('has all expected values', () {
      expect(ParamStyle.values, hasLength(3));
      expect(ParamStyle.form, isA<ParamStyle>());
      expect(ParamStyle.simple, isA<ParamStyle>());
      expect(ParamStyle.matrix, isA<ParamStyle>());
    });
  });

  group('ParamLocation', () {
    test('has all expected values', () {
      expect(ParamLocation.values, hasLength(2));
      expect(ParamLocation.header, isA<ParamLocation>());
      expect(ParamLocation.query, isA<ParamLocation>());
    });
  });

  group('ParamDoc', () {
    test('toOpenApi returns correct map', () {
      const param = ParamDocString(
        name: 'page',
        location: ParamLocation.query,
        description: 'Page number',
      );
      final map = param.toOpenApi();
      expect(map['name'], 'page');
      expect(map['in'], 'query');
      expect(map['description'], 'Page number');
      expect(map['required'], false);
      expect(map['deprecated'], false);
      expect(map['schema'], {'type': 'string'});
    });

    test('toOpenApi includes optional fields when set', () {
      const param = ParamDocString(
        name: 'q',
        location: ParamLocation.query,
        description: 'Search query',
        required: true,
        example: 'dart',
      );
      final map = param.toOpenApi();
      expect(map['required'], isTrue);
      expect(map['deprecated'], isFalse);
      expect(map['example'], 'dart');
    });
  });

  group('ParamDocString', () {
    test('schemaDoc returns string type', () {
      const param = ParamDocString(
        name: 'name',
        location: ParamLocation.query,
        description: 'Name',
      );
      final schema = param.schemaDoc;
      expect(schema.schema['type'], 'string');
    });

    test('schemaDoc includes optional fields', () {
      const param = ParamDocString(
        name: 'q',
        location: ParamLocation.query,
        description: 'Query',
        minLength: 1,
        maxLength: 100,
        pattern: r'^[a-z]+$',
        nullable: true,
        defaultValue: 'default',
      );
      final schema = param.schemaDoc;
      expect(schema.schema['minLength'], 1);
      expect(schema.schema['maxLength'], 100);
      expect(schema.schema['pattern'], r'^[a-z]+$');
      expect(schema.schema['nullable'], isTrue);
      expect(schema.schema['default'], 'default');
    });
  });

  group('ParamDocNumber', () {
    test('schemaDoc returns number type', () {
      const param = ParamDocNumber(
        name: 'count',
        location: ParamLocation.query,
        description: 'Count',
      );
      final schema = param.schemaDoc;
      expect(schema.schema['type'], 'number');
    });

    test('schemaDoc includes optional fields', () {
      const param = ParamDocNumber(
        name: 'count',
        location: ParamLocation.query,
        description: 'Count',
        minimum: 0,
        maximum: 100,
        nullable: true,
        defaultValue: 10,
      );
      final schema = param.schemaDoc;
      expect(schema.schema['minimum'], 0);
      expect(schema.schema['maximum'], 100);
      expect(schema.schema['nullable'], isTrue);
      expect(schema.schema['default'], 10);
    });
  });

  group('ParamDocBoolean', () {
    test('schemaDoc returns boolean type', () {
      const param = ParamDocBoolean(
        name: 'active',
        location: ParamLocation.query,
        description: 'Active flag',
      );
      final schema = param.schemaDoc;
      expect(schema.schema['type'], 'boolean');
    });

    test('schemaDoc includes default value', () {
      const param = ParamDocBoolean(
        name: 'active',
        location: ParamLocation.query,
        description: 'Active',
        defaultValue: true,
      );
      final schema = param.schemaDoc;
      expect(schema.schema['default'], isTrue);
    });
  });

  group('SwaggerInfo mixin', () {
    test('provides default values', () {
      final info = _TestSwaggerInfo();
      expect(info.description, '');
      expect(info.descriptionBody, isNull);
      expect(info.requiresAuth, isFalse);
      expect(info.responses, isEmpty);
      expect(info.dependentSchemas, isEmpty);
      expect(info.requestBodySchema, isNull);
      expect(info.parameters, isEmpty);
    });
  });
}

class _TestSwaggerInfo with SwaggerInfo {
  @override
  String get description => '';

  @override
  Map<int, ResponseDoc> get responses => const {};
}
