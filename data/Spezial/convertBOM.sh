#!/bin/bash


if [ $# -ge 2 ]
then
	echo -ne "\xEF\xBB\xBF" > "$2"
	cat "$1" >> "$2"
else
	echo "Usage: $(basename "$0") <orig file> <output file>"
fi

