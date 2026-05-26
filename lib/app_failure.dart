/// Declarative failure handling for Dart and Flutter applications.
///
/// `app_failure` provides structured failure objects, layered failure chains,
/// and lightweight result handling.
///
/// The package helps applications preserve failure context across layers
/// instead of relying on hidden exception propagation.
library;

export 'src/app_failure.dart';
export 'src/app_result.dart';

export 'src/failure_types/http_failure/http_failure_kind.dart';
export 'src/failure_types/http_failure/http_failure_request_model.dart';
export 'src/failure_types/http_failure/http_failure_response_model.dart';