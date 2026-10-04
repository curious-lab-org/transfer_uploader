# 8. No login, no scoping

## Status

Accepted — 2026-10-03

## Context

The brief loads balances and applies transfers. Nobody mentions users.

## Decision

One company's data, and everyone who can reach the app sees all of it. No `companies`
table, no `company_id`, no scoping on any query. No sign-in, no sessions, no user
records.

## Consequences

- The code is about transfer rules instead of tenancy and permissions.
- Anyone who can reach the application can move money, so it can't go on a network we
  don't control.
