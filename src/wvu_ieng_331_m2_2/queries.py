"""Data access module.

Reads SQL files from the sql/ directory and executes them against DuckDB,
returning Polars DataFrames.  No inline SQL appears in this file.
"""

from __future__ import annotations

from datetime import date
from pathlib import Path

import duckdb
import polars as pl

# Resolve the sql/ directory relative to this file's location:
# src/wvu_ieng_331_m2/queries.py  →  ../../sql/
_SQL_DIR = Path(__file__).parent.parent.parent / "sql"
#helpers

def _load_sql(filename: str) -> str:
    """Read a SQL file from the sql/ directory.

    Args:
        filename: Name of the .sql file (e.g. ``'seller_scorecard.sql'``).

    Returns:
        The raw SQL string.

    Raises:
        FileNotFoundError: If the SQL file does not exist.
    """
    # build path and verify oyutput
    path = _SQL_DIR / filename
    if not path.exists():
        raise FileNotFoundError(f"SQL file not found: {path}")
    return path.read_text(encoding="utf-8")


def _execute(
    db_path: str | Path,
    sql: str,
    params: list | None = None,
) -> pl.DataFrame:
    """Execute a parameterized SQL query against DuckDB and return a Polars DataFrame.

    Args:
        db_path: Path to the DuckDB database file.
        sql: Parameterized SQL string (uses ``$1``, ``$2`` placeholders).
        params: Ordered list of parameter values to bind.

    Returns:
        Query results as a Polars DataFrame.

    Raises:
        FileNotFoundError: If the database file does not exist.
        duckdb.Error: If the query fails.
    """
    # verify db file exists
    db_path = Path(db_path)
    if not db_path.exists():
        raise FileNotFoundError(f"Database not found: {db_path}")

    # open read-only and close
    con = duckdb.connect(str(db_path), read_only=True)
    try:
        result = con.execute(sql, params or []).fetchall()
        columns = [desc[0] for desc in con.description]  # type: ignore[union-attr]
        return pl.DataFrame(result, schema=columns, orient="row")
    finally:
        con.close()
