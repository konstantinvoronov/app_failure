part of '../app_failure.dart';

/// PermissionFailure - permission denied/restricted/permanently denied
/// Example: denied location permission, unauthorized action, missing role.

final class PermissionFailure extends AppFailure {
  PermissionFailure({
    String? uiMessage,
    required String logMessage,
    AppFailure? cause,
    Object? error,
    StackTrace? stackTrace,
    FatalLevel fatalLevel = FatalLevel.nonFatal,
    bool? showReportBugDialog,
  }) : super._(
         uiMessage: uiMessage,
         logMessage: logMessage,
         cause: cause,
         error: error,
         stackTrace: stackTrace,
         fatalLevel: fatalLevel,
         showReportBugDialog: showReportBugDialog,
       );
}
