#!/bin/bash

source $(dirname "$0")/.config.sh

echo "PRAGMA foreign_keys=ON;" > "$SQLFILE"
echo "BEGIN TRANSACTION;" >> "$SQLFILE"
# Manually querying sqlite_master because ".schema --indent --nosys" inserts new automatic comments each time after VIEW definitions
sqlite3 "$DBFILE" "SELECT sql||';' FROM sqlite_master WHERE name NOT LIKE 'sqlite_%'" ".dump --data-only --nosys" >> "$SQLFILE"
echo "COMMIT;" >> "$SQLFILE"
