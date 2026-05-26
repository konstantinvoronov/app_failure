part of '../app_failure.dart';


/// PerformanceFailure - Represents slow or degraded operation. (silent error, design for logging or debugging)
/// Example: operation exceeded expected time, timeout-like UX warning, benchmark alert.
final class PerformanceFailure extends AppFailure {
  PerformanceFailure(String text, {
    StackTrace? stackTrace,
  }) : super._(
    logMessage: text,
    stackTrace: stackTrace ?? StackTrace.current,
  );
}
