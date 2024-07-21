#!/bin/bash

source $(dirname "$0")/.config

if [ -f "$DBFILE" ]
then
	if [ "$1" = "-f" ]
	then
		rm "$DBFILE"
	else
		echo "Database file already exists. Type \"y\" to confirm. Use flag \"-f\" to overwrite it without warning."
		rm -i "$DBFILE"
	fi
	[ -f "$DBFILE" ] && exit 1
fi

sqlite3 "$DBFILE" < "$SQLFILE"
