# Changelog

## 1.0.1

- Initial package setup.
- Added the core `AppFailure` model.
- Added `AppResult<T>` for explicit success and failure return flows.
- Added support for failure cause chains.
- Added base failure types for validation, HTTP, API, repository, and controller layers.
- Added failure metadata for log messages, UI messages, severity, stack traces, and report behavior.
- Added early documentation for the declarative failure-handling model.
- Added examples for:
    - returning `AppResult<T>` instead of throwing
    - wrapping lower-level failures into higher-level failures
    - preserving the full failure chain
    - logging the full chain only when the failure is consumed
    - emitting failures to the UI for user-facing reactions
- Prepared package structure for adapters, integration examples, and future processing rules.