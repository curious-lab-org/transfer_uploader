# 12. Record every line's outcome on the transfers table

## Status

Accepted - 2026-10-03

## Context

Once processing moved out of the request we can't hand an in-memory report
back to whoever uploaded the file, so the outcome has to survive the job, the process
and a restart.

## Decision

A line of the file and the transfer it asks for are the same thing, so they are one
row. `transfers` holds every parseable line of the file, with its `outcome` -
`applied` or `rejected` - its `row_number`, and a `reason` when it was refused.
A line we can't parse has no transfer, so it fails the run instead. The
verdict is known when we write the row, because parsing and applying happen in
one pass inside one transaction. It's one insert per line and every outcome
commits with the balance change it describes.