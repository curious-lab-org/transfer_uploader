# 12. Record every line's outcome on the transfers table

## Status

Accepted — 2026-10-03

## Context

Once processing moved out of the request (ADR-10) we can't hand an in-memory report
back to whoever uploaded the file, so the outcome has to survive the job, the process
and a restart.

## Decision

A line of the file and the transfer it asks for are the same thing, so they are one
row. `transfers` holds every parseable line of the file, with its `outcome` —
`applied` or `rejected` — its `row_number`, and a `reason` when it was refused
(ADR-3). A line we can't parse has no transfer to be, so it fails the run instead
(ADR-6). The verdict is known when we write the row, because parsing and applying
happen in one pass inside one transaction (ADR-4), so it's one insert per line and
every outcome commits with the balance change it describes.