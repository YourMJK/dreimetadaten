#!/bin/bash

while read line
do
	f1=$(echo "$line" | cut -f1)
	f2=$(echo "$line" | cut -f2)
	echo "        ["
	echo "          \"$f1\","
	echo "          \"$f2\""
	echo "        ],"
done < "$1"
