/// Describes the general kind of HTTP failure.
///
/// `HttpFailureKind` is used to classify HTTP-related failures into
/// predictable categories. This makes it easier to handle different network
/// and response failure cases without depending directly on a specific HTTP
/// client exception type.
enum HttpFailureKind {
  /// The server returned a response, but the response is considered invalid
  /// or unsuccessful.
  ///
  /// This usually represents non-success HTTP status codes or responses that
  /// the application decided to treat as failures.
  badResponse,

  /// The connection could not be established before the connection timeout
  /// was reached.
  connectionTimeout,

  /// The request could not be sent before the send timeout was reached.
  sendTimeout,

  /// The response was not received before the receive timeout was reached.
  receiveTimeout,

  /// The request failed because of an invalid, rejected, or untrusted
  /// certificate.
  badCertificate,

  /// The request was cancelled before it completed.
  cancelled,

  /// The request failed because of a network connection problem.
  ///
  /// This can include cases such as no internet connection, DNS failure,
  /// socket failure, or another lower-level connection issue.
  connectionError,

  /// The HTTP failure could not be classified into one of the known kinds.
  unknown,
}
