#!/bin/bash

source $(dirname "$0")/.config

echo "PRAGMA foreign_keys=ON;" > "$SQLFILE"
echo "BEGIN TRANSACTION;" >> "$SQLFILE"
sqlite3 "$DBFILE" ".schema --indent --nosys" ".dump --data-only --nosys" >> "$SQLFILE"
echo "COMMIT;" >> "$SQLFILE"
