part of '../app_failure.dart';

final class ControllerFailure extends AppFailure {
  // old: AppFailure.voidError(error, stackTrace)
  ControllerFailure.voidError(Object? error, StackTrace stackTrace)
      : super._(
    logMessage: 'void ${error.toString()}',
    stackTrace: stackTrace,
    error: error,
  );

  // old: AppFailure.usecaseException(...)
  ControllerFailure.usecaseException({
    String? uiMessage,
    String? logMessage,
    Object? cause,
    required Object error,
    required StackTrace stackTrace,
    FatalLevel? fatalLevel,
    bool? showReportBugDialog,
  }) : super._(
    uiMessage: uiMessage,
    logMessage: 'Usecase exception: ${logMessage ?? ''} ${error.toString()}',
    cause: AppFailure.extractCause(cause),
    error: error,
    stackTrace: stackTrace,
    fatalLevel: fatalLevel ?? FatalLevel.nonFatal,
    showReportBugDialog: showReportBugDialog,
  );

  ControllerFailure({
    String? uiMessage,
    required String logMessage,
    Object? cause,
    Object? error,
    StackTrace? stackTrace,
    FatalLevel fatalLevel = FatalLevel.nonFatal,
    bool? showReportBugDialog,
  }) : super._(
    uiMessage: uiMessage,
    logMessage: logMessage,
    cause: AppFailure.extractCause(cause),
    error: error,
    stackTrace: stackTrace,
    fatalLevel: fatalLevel,
    showReportBugDialog: showReportBugDialog,
  );
}
