/// Core failure model for the `app_failure` package.
///
/// This file defines [AppFailure], the shared failure contract used across
/// application layers.
///
/// The main idea is that failures should not replace each other as they move
/// through the app. Each layer wraps a lower-level failure with its own
/// context while preserving the original failure as [cause].
///
/// Example:
///
/// ```text
/// HttpFailure
///   -> ApiFailure
///     -> RepositoryFailure
///       -> ControllerFailure
/// ```
///
/// This allows the UI to process a high-level failure while logs, reports,
/// and diagnostics still contain the full root-cause chain.

import 'failure_types/http_failure/http_failure_request_model.dart';
import 'failure_types/http_failure/http_failure_response_model.dart';
import 'failure_types/http_failure/http_failure_kind.dart';


part 'failure_types/validation_failure.dart';
part 'failure_types/http_failure/http_failure.dart';
part 'failure_types/api_failure.dart';
part 'failure_types/repository_failure.dart';
part 'failure_types/performance_failure.dart';
part 'failure_types/permission_failure.dart';
part 'failure_types/controller_failure.dart';
part 'failure_types/unhandled_failure.dart';

/// Describes how severe a failure is for the application flow.
enum FatalLevel {
  /// The failure is recoverable and should not stop the feature or app.
  nonFatal,

  /// The current feature cannot continue safely, but the app can keep running.
  featureFatal,

  /// The app cannot continue safely and should be handled by a global processor.
  appFatal,

  /// The failure should be processed without showing user-facing feedback.
  silent,

  /// Severity was not classified.
  unknown,
}

/// Shared base class for all application failures.
///
/// [AppFailure] is the external failure contract of the app.
/// It is intended to be returned, wrapped, stored in state, logged,
/// reported, or processed by UI/global handlers.
sealed class AppFailure {
  /// Optional user-facing message.
  ///
  /// Message resolution is project-specific. Some projects may prefer the
  /// outermost message, others may prefer the root-cause message or a custom
  /// resolver.
  final String? uiMessage;

  /// Developer-facing message used for logs and diagnostics.
  final String logMessage;

  /// Lower-level failure that caused this failure.
  ///
  /// Used to preserve the full failure chain across layers.
  final AppFailure? cause;

  /// Raw thrown error or exception.
  ///
  /// Must not contain another [AppFailure]. If an [AppFailure] is passed as
  /// [error], it is automatically moved to [cause].
  final Object? error;

  /// Stack trace captured at the layer where this failure was created.
  final StackTrace? stackTrace;

  /// Severity of the failure.
  final FatalLevel fatalLevel;

  /// Whether the UI/global processor should suggest a bug report flow.
  final bool? showReportBugDialog;

  const AppFailure._({
    required this.logMessage,
    String? this.uiMessage,
    AppFailure? cause,
    Object? error,
    this.stackTrace,
    this.fatalLevel = FatalLevel.nonFatal,
    this.showReportBugDialog,
  })  : cause = error is AppFailure ? error as AppFailure : cause,
        error = error is AppFailure ? null : error;


  /// Creates an API-level failure.
  ///
  /// Use this when an API response, API contract, or API processing step fails.
  ///
  /// If the caught [error] is already an [AppFailure], it is automatically moved
  /// into [cause] by the base constructor. This allows local throw-to-catch
  /// patterns without manually unpacking the failure chain.
  ///
  /// Example:
  ///
  /// ```dart
  /// try {
  ///   throw AppFailure.HttpFailure(...);
  /// } catch (error, stackTrace) {
  ///   return AppFailure.ApiFailure(
  ///     logMessage: 'API processing failed',
  ///     error: error,
  ///     stackTrace: stackTrace,
  ///   );
  /// }
  /// ```
  ///
  /// In this example, the thrown `HttpFailure` becomes the `cause` of the
  /// returned `ApiFailure`.
  factory AppFailure.ApiFailure({
    String? uiMessage,
    String? logMessage,
    Object? cause,
    Object? error,
    HttpFailureRequestModel? request,
    HttpFailureResponseModel? response,
    required StackTrace stackTrace,
    FatalLevel? fatalLevel,
    bool? showReportBugDialog,
  }) = ApiFailure;

  /// Creates an unhandled failure from an unexpected raw error.
  ///
  /// Use this as the fallback when no more specific failure type applies.
  factory AppFailure.UnhandledFailure({
    String? uiMessage,
    String? logMessage,
    required Object error,
    required StackTrace stackTrace,
    FatalLevel? fatalLevel,
    bool? showReportBugDialog,
  }) = UnhandledFailure;


  /// Creates an HTTP-level failure without depending on a concrete HTTP client.
  ///
  /// Technology-specific packages such as Dio adapters should map their own
  /// request/response objects into [HttpFailureRequestModel] and
  /// [HttpFailureResponseModel].
  factory AppFailure.HttpFailure({
    String? uiMessage,
    String? logMessage,
    AppFailure? cause,
    Object? error,
    required HttpFailureRequestModel request,
    HttpFailureResponseModel? response,
    HttpFailureKind failureKind,
    String? debugDescription,
    required StackTrace stackTrace,
    bool? showReportBugDialog,
    FatalLevel fatalLevel,
  }) = HttpFailure;


  /// Creates a repository/use-case-level failure.
  ///
  /// Use this when a repository operation fails. Preserve lower-level failures
  /// as [cause].
  factory AppFailure.RepositoryFailure({
    String? uiMessage,
    String? logMessage,
    Object? cause,
    required StackTrace stackTrace,
    FatalLevel? fatalLevel,
    bool? showReportBugDialog,
  }) = RepositoryFailure;

  /// Creates a ui- controller/ failure.
  ///
  /// Use this when a feature flow or controller operation cannot complete.
  factory AppFailure.ControllerFailure({
    String? uiMessage,
    required String logMessage,
    Object? cause,
    StackTrace? stackTrace,
    FatalLevel fatalLevel,
    bool? showReportBugDialog,
  }) = ControllerFailure;

  /// Creates a validation failure.
  ///
  /// Use this when data does not match the contract expected by the current
  /// layer. This includes form validation, domain validation, and mapper
  /// conversion failures caused by invalid external data.
  factory AppFailure.ValidationFailure(String uiMessage) = ValidationFailure;

  /// Creates a permission failure.
  ///
  /// Use this when an operation cannot continue because permission is denied,
  /// restricted, missing, or permanently denied.
  factory AppFailure.PermissionFailure(String uiMessage) = ValidationFailure;

  /// Creates a performance failure.
  ///
  /// Use this when an operation takes longer than expected or violates a
  /// performance threshold.
  factory AppFailure.PerformanceFailure(String text, {StackTrace? stackTrace,}) = PerformanceFailure;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other.runtimeType == runtimeType &&
            other is AppFailure &&
            other.uiMessage == uiMessage &&
            other.logMessage == logMessage &&
            other.fatalLevel == fatalLevel;
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    uiMessage,
    logMessage,
    fatalLevel,
  );

  @override
  String toString() {
    final b = StringBuffer();
    b.writeln('\n\n\n[Failure] $runtimeType');
    b.writeln('[Fatality] $fatalLevel');

    final ui = (uiMessage ?? '').trim();
    if (ui.isNotEmpty) b.writeln('[UI Message] $ui');

    final log = (logMessage).trim();
    if (log.isNotEmpty) _writeMultiline(b, log);

    _writeStack(b, stackTrace);
    _writeCauseChain(b, cause, 1);
    return b.toString().trimRight();
  }

  static const int _maxStackLines = 15;
  static const int _maxCauseDepth = 8;

  void _writeStack(StringBuffer b, StackTrace? st) {
    if (st == null) return;
    final lines = st.toString().split(RegExp(r'\r?\n'));
    b.writeln('[StackTrace]');
    final limit = _maxStackLines;
    final end = limit < lines.length ? limit : lines.length;
    for (var i = 0; i < end; i++) {
      b.writeln(lines[i]);
    }
    if (lines.length > limit) {
      b.writeln('... [${lines.length - limit} more lines]');
    }
  }

  void _writeCauseChain(StringBuffer b, Object? cause, int depth) {
    if (cause == null || depth > _maxCauseDepth) return;
    if (cause is AppFailure) {
      b.writeln('[Cause $depth] ${cause.runtimeType}');
      final log = (cause.logMessage).trim();
      if (log.isNotEmpty) _writeMultiline(b, log);
      _writeStack(b, cause.stackTrace);
      _writeCauseChain(b, cause.cause, depth + 1);
    } else {
      b.writeln('[Cause $depth] $cause');
    }
  }

  static AppFailure? extractCause(Object? raw) {
    if (raw is AppFailure) return raw;

    if (raw is Exception) {
      return AppFailure.UnhandledFailure(
        error: raw,
        logMessage: raw.toString(),
        stackTrace: StackTrace.current,
      );
    }
    if (raw != null) {
      return AppFailure.UnhandledFailure(
        error: raw,
        logMessage: 'unknown cause type',
        stackTrace: StackTrace.current,
      );
    }
    return null;
  }

  void _writeMultiline(StringBuffer b, String text) {
    final lines = text.split('\n');
    final limit = _maxStackLines;
    final end = limit < lines.length ? limit : lines.length;
    for (var i = 0; i < end; i++) {
      b.writeln(lines[i]);
    }
    if (lines.length > limit) {
      b.writeln('... [${lines.length - limit} more lines]');
    }
  }
}
