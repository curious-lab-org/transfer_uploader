# 7. Accept the transfers CSV over HTTP, with its business date

## Status

Accepted - 2026-10-03

## Context

A company sends a transfers file each day so need to understand where the input comes from.

## Decision

One HTML upload page for the day's transfers, taking the file and the business date
together. The controller records the upload and hands processing off, then
redirects to the upload's status page, which shows the run's state and then the
report.
