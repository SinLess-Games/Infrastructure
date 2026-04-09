# Validation

Use `validation/` for operational checks against the live cluster.

## Production

- `prod/scripts/`
  Shell scripts for phase checks, smoke tests, and debug collection.
- `prod/matrices/`
  Validation matrices and expected-state references.
- `prod/examples/`
  Example manifests and reference validation objects used for testing.

## Rule

Validation content belongs here, not mixed into the app folders, unless a manifest is required for the app itself.
