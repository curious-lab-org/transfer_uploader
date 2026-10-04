# 11. Accept one completed upload per business date

## Status

Accepted — 2026-10-03

## Context

Applying a transfers file moves money, and nothing stops that happening twice. Someone
double-clicks, refreshes, or re-exports Monday's file and sends it again because they
aren't sure the first one worked. 

## Decision

A business date accepts one completed upload. A second file for a date that already
has one is refused.
