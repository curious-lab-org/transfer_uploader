# 4. Apply transfers sequentially with per-transfer rejection

## Status

Accepted - 2026-10-03

## Context

A file holds several transfers and some may be invalid. The lines don't depend on
each other, so one refused transfer doesn't have to stop the day.

Order matters because of the overdraft rule: with `A` holding $100, `B -> A 500` then
`A -> C 300` both succeed, but reversed the second has only $100 behind it. We pick
file order - it's what the company wrote, it's repeatable, and a rejection can be
explained in terms of it.

## Decision

One transaction for the whole run, and inside it one transfer at a time in file order.
A day's file is thousands of lines ( assumption ), so the transaction is short
enough not to engineer around. In exchange an upload is atomic - no half-applied
uploads, resumption, progress reporting or partial failure states.

For each line: look up both accounts, check the source
covers it (`balance_cents < amount_cents`, reject), then debit, credit and record it
as applied. The debit is conditional in the statement that performs it:

```sql
UPDATE accounts SET balance_cents = balance_cents - :amount
WHERE id = :id AND balance_cents >= :amount
```

so the check and the write can't come apart, and zero rows affected is the rejection.

A rejection is a result, not an exception.

A run stops for a line we can't parse (ADR-6).

## Consequences

- An upload is all-or-nothing, so `failed` means no money moved.