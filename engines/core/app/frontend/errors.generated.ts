// Generated from config/errors.yml; do not edit.
export const errors = {
  "auth.expired": { status: 401, retryable: false },
  "auth.forbidden": { status: 403, retryable: false },
  "request.csrf_failed": { status: 422, retryable: true },
  "request.entity_too_large": { status: 413, retryable: false },
  "request.invalid": { status: 400, retryable: false },
  "request.throttled": { status: 429, retryable: true },
  "resource.conflict": { status: 409, retryable: false },
  "resource.not_found": { status: 404, retryable: false },
  "unexpected": { status: 500, retryable: true },
  "upstream.circuit_open": { status: 503, retryable: true },
  "upstream.timeout": { status: 504, retryable: true },
  "upstream.unavailable": { status: 503, retryable: true },
  "validation.failed": { status: 422, retryable: false },
} as const;
