import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:coolson/coolson.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:mime/mime.dart';
import 'package:shelf/shelf.dart';

/// A base class for standardizing successful API responses.
///
/// By sealing this class, we ensure that all possible success responses are
/// explicitly defined and handled, leading to more predictable API behavior.
/// Each entity is responsible for converting itself into a final Shelf [Response].
@immutable
sealed class ResponseEntity extends Equatable {
  const ResponseEntity();

  Response get response;

  @override
  bool? get stringify => true;
}

/// A [ResponseEntity] for streaming a file as the response body.
///
/// This is useful for serving downloads or file-based content without loading
/// the entire file into memory.
final class FileResponse extends ResponseEntity {
  const FileResponse({
    required this.data,
    String? mimeType = 'application/octet-stream',
  }) : _mimeType = mimeType ?? 'application/octet-stream';

  static Future<FileResponse> fromFile({
    required File file,
    String? contentType,
  }) async {
    return FileResponse(
      data: await file.readAsBytes(),
      mimeType: contentType ?? lookupMimeType(file.path),
    );
  }

  final Uint8List data;

  final String _mimeType;

  @override
  Response get response {
    final headers = {
      HttpHeaders.contentTypeHeader: _mimeType,
      HttpHeaders.contentLengthHeader: data.length.toString(),
    };

    return Response.ok(data, headers: headers);
  }

  @override
  List<Object?> get props => [data, _mimeType];
}

/// A [ResponseEntity] for sending a plain string as the response body.
///
/// This is a general-purpose response type for simple text-based content.
base class ContentResponse extends ResponseEntity {
  const ContentResponse({required this.content, required this.contentType});

  final String content;

  final ContentType contentType;

  @override
  Response get response {
    return Response.ok(
      content,
      headers: {HttpHeaders.contentTypeHeader: contentType.value},
    );
  }

  @override
  List<Object?> get props => [content, contentType];
}

/// A [ResponseEntity] for sending a JSON response.
///
/// This class takes a Dart [Map] and handles its conversion to a JSON stream,
/// setting the appropriate headers automatically.
base class JsonResponse extends ResponseEntity {
  const JsonResponse(this.body, {this.headers});

  final Map<String, dynamic> body;
  final Map<String, dynamic>? headers;

  @override
  Response get response {
    final responseHeaders = <String, Object>{
      HttpHeaders.contentTypeHeader: ContentType.json.value,
    };

    if (headers != null) {
      for (final MapEntry(:key, :value) in headers?.entries ?? const []) {
        if (value == null) continue;
        responseHeaders[key] = switch (value) {
          final String v => v,
          final Iterable<String> v => v.toList(),
          final Iterable v => v.nonNulls.map((e) => e.toString()).toList(),

          final v => v.toString(),
        };
      }
    }

    return Response.ok(body.asJsonStream, headers: responseHeaders);
  }

  @override
  List<Object?> get props => [body];
}

base class EmptyResponse extends ResponseEntity {
  const EmptyResponse({this.headers});

  final Map<String, dynamic>? headers;

  @override
  Response get response {
    final responseHeaders = <String, Object>{
      HttpHeaders.contentTypeHeader: ContentType.json.value,
    };

    if (headers != null) {
      for (final MapEntry(:key, :value) in headers?.entries ?? const []) {
        if (value == null) continue;
        responseHeaders[key] = switch (value) {
          final String v => v,
          final Iterable<String> v => v.toList(),
          final Iterable v => v.map((e) => e.toString()).toList(),

          final v => v.toString(),
        };
      }
    }

    return Response.ok(
      null,
      headers: responseHeaders,
      encoding: Encoding.getByName('utf-8'),
    );
  }

  @override
  List<Object?> get props => [];
}
