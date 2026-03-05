#!/usr/bin/env bash
set -euo pipefail

TMP_DIR=$(mktemp -d)
DB="$TMP_DIR/core.db"
BAK="$TMP_DIR/core.db.bak"

sqlite3 "$DB" "create table if not exists t(id integer primary key, v text); insert into t(v) values ('x');"
sqlite3 "$DB" ".backup $BAK"
INTEGRITY=$(sqlite3 "$DB" "PRAGMA integrity_check;")

if [[ ! -s "$BAK" ]]; then
  echo "backup file not created"
  exit 1
fi
if [[ "$INTEGRITY" != "ok" ]]; then
  echo "integrity check failed: $INTEGRITY"
  exit 1
fi

rm -rf "$TMP_DIR"
echo "ops-smoke: OK"
