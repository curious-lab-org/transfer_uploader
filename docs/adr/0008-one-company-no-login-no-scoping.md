# 8. No login, no scoping

## Status

Accepted - 2026-10-03

## Context

The brief is about transfers and balances no mention of users.

## Decision

One company's data, and everyone who can reach the app sees all of it. No `companies`
table, no `company_id`, no scoping on any query. No sign-in, no sessions, no user
records.

