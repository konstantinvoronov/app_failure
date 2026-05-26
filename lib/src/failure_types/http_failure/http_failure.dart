part of '../../app_failure.dart';

final class HttpFailure extends AppFailure {
  HttpFailure({
    String? uiMessage,
    String? logMessage,
    AppFailure? cause,
    Object? error,
    required this.request,
    this.response,
    this.failureKind = HttpFailureKind.unknown,
    this.debugDescription,
    required StackTrace stackTrace,
    bool? showReportBugDialog,
    FatalLevel fatalLevel = FatalLevel.nonFatal,
  }) : super._(
    uiMessage: uiMessage,
    logMessage: 'HttpFailure: ${logMessage ?? ''}\n${_composeHttp(
      request: request,
      response: response,
      failureKind: failureKind,
      debugDescription: debugDescription,
      error: error,
    )}',
    cause: cause,
    error: error,
    stackTrace: stackTrace,
    showReportBugDialog: showReportBugDialog,
    fatalLevel: fatalLevel,
  );

  final HttpFailureRequestModel request;
  final HttpFailureResponseModel? response;
  final HttpFailureKind failureKind;
  final String? debugDescription;

  int? get statusCode => response?.statusCode;
  Object? get responseBody => response?.body;

  static String _composeHttp({
    required HttpFailureRequestModel request,
    HttpFailureResponseModel? response,
    required HttpFailureKind failureKind,
    String? debugDescription,
    Object? error,
  }) {
    final b = StringBuffer()
      ..write(request.toLogString());

    final responseLog = response?.toLogString().trim();
    if (responseLog != null && responseLog.isNotEmpty) {
      b.writeln(responseLog);
    }

    b.writeln('[Failure Kind] $failureKind');

    final debug = debugDescription?.trim();
    if (debug != null && debug.isNotEmpty) {
      b.writeln('[Debug] $debug');
    }

    if (error != null) {
      b.writeln('[Error] $error');
    }

    return b.toString();
  }
}