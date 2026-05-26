import 'dart:convert';

/// Stores HTTP response information related to a failure.
///
/// This model is used to preserve response context when an HTTP-related
/// operation fails. It can be attached to a failure object or used directly
/// when creating diagnostic logs.
///
/// The model contains optional response status information, headers,
/// and response body.
final class HttpFailureResponseModel {
  /// Creates an HTTP response failure context model.
  ///
  /// [statusCode] is the optional HTTP status code returned by the server.
  ///
  /// [statusMessage] is the optional HTTP status message returned by the server.
  ///
  /// [headers] contains optional response headers.
  ///
  /// [body] contains optional response body data.
  const HttpFailureResponseModel({
    this.statusCode,
    this.statusMessage,
    this.headers,
    this.body,
  });

  /// The HTTP status code returned by the server.
  ///
  /// Examples:
  ///
  /// - `200`
  /// - `400`
  /// - `401`
  /// - `404`
  /// - `500`
  final int? statusCode;

  /// The HTTP status message returned by the server.
  ///
  /// Examples:
  ///
  /// - `OK`
  /// - `Bad Request`
  /// - `Unauthorized`
  /// - `Not Found`
  /// - `Internal Server Error`
  final String? statusMessage;

  /// Optional HTTP response headers.
  ///
  /// Values are typed as [Object?] to support different HTTP client formats.
  final Map<String, Object?>? headers;

  /// Optional HTTP response body.
  ///
  /// The body can be any object depending on how the response was received
  /// and parsed.
  final Object? body;

  /// Converts the stored HTTP response information into a readable log string.
  ///
  /// The log includes:
  ///
  /// - status code and status message, when available
  /// - response headers, when available
  /// - response body, when available
  String toLogString() {
    final b = StringBuffer();

    if (statusCode != null || statusMessage != null) {
      b.writeln('[Status] $statusCode $statusMessage');
    }

    if (headers != null && headers!.isNotEmpty) {
      b.writeln('[Response Headers] ${jsonEncode(headers)}');
    }

    if (body != null) {
      b.writeln('[Response Body] $body');
    }

    return b.toString();
  }
}