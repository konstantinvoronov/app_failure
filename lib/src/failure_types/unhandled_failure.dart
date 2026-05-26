part of '../app_failure.dart';

final class UnhandledFailure extends AppFailure {
  UnhandledFailure({
    String? uiMessage,
    String? logMessage,
    Object? cause,
    required Object error,
    required StackTrace stackTrace,
    FatalLevel? fatalLevel,
    bool? showReportBugDialog,
  }) : super._(
         uiMessage: uiMessage,
         logMessage: 'Unexpected exception ${error.toString()}',
         cause: AppFailure.extractCause(cause),
         error: error,
         stackTrace: stackTrace,
         fatalLevel: fatalLevel ?? FatalLevel.nonFatal,
         showReportBugDialog: showReportBugDialog,
       );
}
