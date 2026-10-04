# 5. Keep transfer logic in service objects

## Status

Accepted — 2026-10-03

## Context

In a controller the rules are only reachable through an HTTP request, so testing the
overdraft rule means uploading a file.

## Decision

Rules in service objects, Rails at the edges.

The controller hands off an upload and holds no rules.
