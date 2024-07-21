#!/bin/bash

source $(dirname "$0")/.config

sqlite3 "$DBFILE" < "$SQLFILE"
