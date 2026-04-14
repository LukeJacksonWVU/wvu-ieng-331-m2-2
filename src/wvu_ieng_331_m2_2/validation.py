from __future__ import annotations

from datetime import date, datetime
from pathlib import Path

import duckdb
from loguru import logger

# ---------------------------------------------------------------------------
# Expected schema
# ---------------------------------------------------------------------------
EXPECTED_TABLES: set[str] = {
    "category_translation",
    "customers",
    "geolocation",
    "order_items",
    "order_payments",
    "order_reviews",
    "orders",
    "products",
    "sellers",
}

KEY_COLUMNS: dict[str, list[str]] = {
    "orders": ["order_id", "customer_id"],
    "order_items": ["order_id", "product_id", "seller_id"],
    "customers": ["customer_id"],
    "products": ["product_id"],
    "sellers": ["seller_id"],
}
