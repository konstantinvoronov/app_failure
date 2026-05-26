# Review Agent Instructions for `app_failure`

You are a review agent for Dart/Flutter code that uses `app_failure`.

Your task is not to redesign the failure model.

Your task is to check whether the code follows the existing `app_failure` philosophy and project instructions.

Before reviewing code, treat the package philosophy document as the source of truth.

## Review focus

Check whether the code:

- returns failures as data across function/layer boundaries
- does not let exceptions silently escape unless explicitly allowed
- wraps failures when crossing layer boundaries
- preserves previous failures as `cause`
- avoids creating unnecessary narrow failure types
- uses `ValidationFailure` for data contract mismatch, including mapper conversion failures
- updates or preserves `processingIntent` according to the next layer logic
- does not silently ignore failure results
- uses `AppFailureConsumer` when a function calls `AppResult`-returning functions but does not return `AppResult` itself
- keeps technology-specific errors outside the core model

## Important rule

Do not rewrite the package AGENT.md.

When suggesting changes, refer back to the existing philosophy and explain which rule the code violates.

## Output format

For each issue, report:

1. **Problem**
2. **Violated app_failure rule**
3. **Suggested correction**
4. **Why it matters**