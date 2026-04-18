# wvu-ieng-331-m2-2
WVU IENG 331 Project Milestone 2 Group 2

**Team 2**: Luke Jackson, Gavin Miller, William Muhly

## How to Run

Instructions to run the pipeline from a fresh clone:

```bash
git clone https://github.com/LukeJacksonWVU/wvu-ieng-331-m2-2.git
cd wvu-ieng-331-m2-2
uv sync
# place olist.duckdb in the data/ directory
uv run wvu-ieng-331-m2-2
uv run wvu-ieng-331-m2-2 --start-date 2026-01-01 --seller-state SP
```

## Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `--start-date` | date | None (no filter) | ... |
| `--end-date` | date | None (no filter) | ... |
| ... | ... | ... | ... |

## Outputs

Describe each output file: what it contains, what format, and how to interpret it.

## Validation Checks

List each validation check your pipeline runs before analysis and what happens if it fails.

## Analysis Summary

Brief narrative of your analytical findings (carried forward from M1, updated if needed).

## Limitations & Caveats

What the pipeline does not handle, known edge cases, etc.
