import 'dart:convert';

/// Stores HTTP request information related to a failure.
///
/// This model is used to preserve request context when an HTTP-related
/// operation fails. It can be attached to a failure object or used directly
/// when creating diagnostic logs.
///
/// The model contains the request method, target URI, optional headers,
/// and optional request body.
final class HttpFailureRequestModel {
  /// Creates an HTTP request failure context model.
  ///
  /// [method] is the HTTP method used for the request.
  ///
  /// [uri] is the target request URI.
  ///
  /// [headers] contains optional request headers.
  ///
  /// [body] contains optional request body data.
  const HttpFailureRequestModel({
    required this.method,
    required this.uri,
    this.headers,
    this.body,
  });

  /// The HTTP method used for the request.
  ///
  /// Examples:
  ///
  /// - `GET`
  /// - `POST`
  /// - `PUT`
  /// - `DELETE`
  final String method;

  /// The target URI of the HTTP request.
  final Uri uri;

  /// Optional HTTP request headers.
  ///
  /// Values are typed as [Object?] to support different HTTP client formats.
  final Map<String, Object?>? headers;

  /// Optional HTTP request body.
  ///
  /// The body can be any object depending on how the request was created.
  final Object? body;

  /// Converts the stored HTTP request information into a readable log string.
  ///
  /// The log includes:
  ///
  /// - HTTP method and URI
  /// - URL method and URI
  /// - headers, when available
  /// - body, when available
  String toLogString() {
    final b = StringBuffer()
      ..writeln('[HTTP $method] $uri')
      ..writeln('[URL $method] $uri');

    if (headers != null && headers!.isNotEmpty) {
      b.writeln('[Headers] ${jsonEncode(headers)}');
    }

    if (body != null) {
      b.writeln('[Body] $body');
    }

    return b.toString();
  }
}
