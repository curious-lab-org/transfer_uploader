# 10. Process uploads in a background job, one at a time

## Status

Accepted - 2026-10-03

## Context

Processing the file inside the upload request ties the run to a request timeout and
leaves nowhere to record a run that fails.

Two files can also be in flight at once - two people, two tabs, or a retry arriving
before the first finishes - and idempotency doesn't stop it.

## Decision

Take the upload in the request, process it in a background job, one upload at a time
across the whole system. The controller stores the file with Active Storage, creates
the upload record and validates parameters, then enqueues the job doesn't involve
any business logic, which is then has concurrency controls.
