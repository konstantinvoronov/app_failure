part of '../app_failure.dart';

/// Represents a failure produced by an API layer.
///
/// [ApiFailure] should be used when the remote API response has already been
/// received or when a lower-level HTTP failure has been interpreted by the API
/// layer.
///
/// This class should not depend on Dio, `package:http`, Chopper, Retrofit, or
/// any other concrete HTTP client.
///
/// The lower HTTP/client layer should capture raw request and response data
/// inside [HttpFailureRequestModel] and [HttpFailureResponseModel]. The API
/// layer can then decide what that response means.
///
/// Example flow:
///
/// ```text
/// DioException / http.ClientException / SocketException
///         ↓
/// HttpFailure
///         ↓
/// ApiFailure
///         ↓
/// RepositoryFailure
///         ↓
/// ControllerFailure
/// ```
///
/// Example:
///
/// ```dart
/// try {
///   final response = await dio.get('/users');
///
///   if (response.statusCode != 200) {
///     final httpFailure = HttpFailure(
///       logMessage: 'Unexpected HTTP response',
///       request: response.requestOptions.toHttpFailureRequestModel(),
///       response: response.toHttpFailureResponseModel(),
///       failureKind: HttpFailureKind.badResponse,
///       debugDescription: response.toString(),
///       stackTrace: StackTrace.current,
///     );
///
///     return AppResult.failure(
///       ApiFailure(
///         logMessage: 'Users API returned unexpected response',
///         cause: httpFailure,
///         stackTrace: StackTrace.current,
///       ),
///     );
///   }
///
///   return AppResult.success(response.data);
/// } on DioException catch (e, st) {
///   final httpFailure = e.toHttpFailure(
///     stackTrace: st,
///     logMessage: 'Dio failed while loading users',
///   );
///
///   return AppResult.failure(
///     ApiFailure(
///       logMessage: 'Users API request failed',
///       cause: httpFailure,
///       error: e,
///       stackTrace: st,
///     ),
///   );
/// }
/// ```
///
/// Dio-specific methods like `toHttpFailureRequestModel`,
/// `toHttpFailureResponseModel`, and `toHttpFailure` live in a Dio
/// adapter extension, not in the core `app_failure` package.
/// 
final class ApiFailure extends AppFailure {
  /// Creates an API-layer failure from dependency-free HTTP request/response
  /// data.
  ///
  /// [request] is required because an API failure should normally be connected
  /// to the request that produced it.
  ///
  /// [response] is optional because the API layer may wrap a lower-level
  /// [HttpFailure] where no server response was received.
  ///
  /// [cause] may be a lower-level [HttpFailure], another [AppFailure], or any
  /// object that can be converted by [AppFailure.extractCause].

  ApiFailure({
    String? uiMessage,
    String? logMessage,
    Object? cause,
    Object? error,
    HttpFailureRequestModel? request,
    HttpFailureResponseModel? response,
    required StackTrace stackTrace,
    FatalLevel? fatalLevel,
    bool? showReportBugDialog,
  })  : request = request ?? _extractRequest(cause),
        response = response ?? _extractResponse(cause),
        super._(
        uiMessage: uiMessage,
        logMessage: 'ApiFailure: ${logMessage ?? ''}\n${_composeApi(
          request: request ?? _extractRequest(cause),
          response: response ?? _extractResponse(cause),
          error: error,
        )}',
        cause: AppFailure.extractCause(cause),
        error: error,
        stackTrace: stackTrace,
        fatalLevel: fatalLevel ?? FatalLevel.nonFatal,
        showReportBugDialog: showReportBugDialog,
      );

  /// Request snapshot used by the API call.
  final HttpFailureRequestModel request;

  /// Optional response snapshot returned by the remote API.
  final HttpFailureResponseModel? response;

  /// HTTP status code from [response], if available.
  int? get statusCode => response?.statusCode;

  /// Response body from [response], if available.
  Object? get responseBody => response?.body;

  static HttpFailureRequestModel _extractRequest(Object? cause) {
    if (cause is HttpFailure) {
      return cause.request;
    }

    throw ArgumentError(
      'ApiFailure requires request when cause is not HttpFailure.',
    );
  }

  static HttpFailureResponseModel? _extractResponse(Object? cause) {
    if (cause is HttpFailure) {
      return cause.response;
    }

    return null;
  }

  static String _composeApi({
    required HttpFailureRequestModel request,
    HttpFailureResponseModel? response,
    Object? error,
  }) {
    final b = StringBuffer()..write(request.toLogString());

    final responseLog = response?.toLogString().trim();
    if (responseLog != null && responseLog.isNotEmpty) {
      b.writeln(responseLog);
    }

    if (error != null) {
      b.writeln('[Error] $error');
    }

    return b.toString();
  }
}