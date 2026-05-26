part of '../app_failure.dart';

final class RepositoryFailure extends AppFailure {
  RepositoryFailure({
    String? uiMessage,
    String? logMessage,
    Object? cause,
    Object? error,
    required StackTrace stackTrace,
    FatalLevel? fatalLevel,
    bool? showReportBugDialog,
  }) : super._(
         uiMessage: uiMessage,
         logMessage:
             'Repository exception: ${logMessage ?? ''} ${error.toString()}',
         cause: AppFailure.extractCause(cause),
         error: error,
         stackTrace: stackTrace,
         fatalLevel: fatalLevel ?? FatalLevel.nonFatal,
         showReportBugDialog: showReportBugDialog,
       );
}
