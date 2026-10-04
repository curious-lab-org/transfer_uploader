# 6. Parse CSV at an explicit boundary layer

## Status

Accepted - 2026-10-03

## Context

Both inputs are headerless CSV with no schema. Every field arrives as a string and
any of them can be wrong: an account number of the wrong length, an amount with
three decimals, a line with two fields or four, a blank line, a header somebody
added, a file that isn't CSV. 

## Decision

Two parsers, per import. The transfers parser runs in the job, the balances parser
in the rake task. Each takes an `IO` and yields, per line, either a valid
domain value or a structured error with the row number, what was wrong, and the
value we got.
