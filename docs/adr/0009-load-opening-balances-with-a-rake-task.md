# 9. Load opening balances with a rake task

## Status

Accepted — 2026-10-03

## Context

The transfers file arrives daily from an operations team with no shell access, so it
needs an upload page (ADR-7). The balances file is loaded once at setup by whoever
deploys, so that argument doesn't reach it so we want to treat these differently.

## Decision

A rake task, `balances:load[path]`, reads a CSV from a path on the server, parses it
with the balances parser (ADR-6), and creates each account with `balance_cents` and
`opening_balance_cents` set to the figure in the file (ADR-3).