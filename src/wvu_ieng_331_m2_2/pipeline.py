"""Pipeline orchestration script.

Entry point for the Milestone 2 analysis pipeline.  Accepts CLI parameters,
runs validation, executes queries, writes output files, and produces a chart.

Usage examples::

    uv run wvu-ieng-331-m2
    uv run wvu-ieng-331-m2 --start-date 2017-01-01 --end-date 2018-12-31
    uv run wvu-ieng-331-m2 --seller-state SP
    uv run wvu-ieng-331-m2 --db-path /path/to/olist.duckdb --seller-state RJ
"""

from __future__ import annotations

import argparse
import sys
from datetime import date
from pathlib import Path

import altair as alt
import duckdb
import polars as pl
from loguru import logger

from wvu_ieng_331_m2_2 import queries, validation

# Default database path (relative to the project root, two levels above src/)
_DEFAULT_DB = Path(__file__).parent.parent.parent / "data" / "olist.duckdb"
_DEFAULT_OUTPUT = Path(__file__).parent.parent.parent / "output"


# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------


def _parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    """Parse command-line arguments.

    Args:
        argv: Argument list (defaults to ``sys.argv[1:]``).

    Returns:
        Parsed namespace with attributes: db_path, start_date, end_date,
        seller_state, halt_on_validation_failure.
    """
    parser = argparse.ArgumentParser(
        prog="wvu-ieng-331-m2",
        description="Olist e-commerce analysis pipeline (WVU IENG 331 Milestone 2).",
    )
    parser.add_argument(
        "--db-path",
        type=Path,
        default=_DEFAULT_DB,
        help="Path to the olist.duckdb file (default: data/olist.duckdb).",
    )
    parser.add_argument(
        "--start-date",
        type=date.fromisoformat,
        default=None,
        metavar="YYYY-MM-DD",
        help="Inclusive start date filter on order_purchase_timestamp.",
    )
    parser.add_argument(
        "--end-date",
        type=date.fromisoformat,
        default=None,
        metavar="YYYY-MM-DD",
        help="Inclusive end date filter on order_purchase_timestamp.",
    )
    parser.add_argument(
        "--seller-state",
        type=str,
        default=None,
        metavar="XX",
        help="Two-letter Brazilian state abbreviation to filter sellers (e.g. SP).",
    )
    parser.add_argument(
        "--halt-on-validation-failure",
        action="store_true",
        default=False,
        help="Halt the pipeline if any validation check fails (default: warn and continue).",
    )
    return parser.parse_args(argv)
