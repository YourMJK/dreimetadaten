#!/bin/bash

source $(dirname "$0")/.config.sh

if [ $# -lt 3 ]
then
	echo 'Add new "medium" to "hörspiel", read embedded chapters in <audio file>, add chapters as "track"s to "medium" and reference those as new "kapitel" appended to "hörspiel".'
	echo "Usage:   $(basename "$0") (--id <hörspielID> | --nr <nummer> | --titel <titel>) <audio file>"
	echo "Example: $(basename "$0") --nr 230 CD.m4a"
	exit 1
fi

ffmpeg -loglevel error -i "$3" -f ffmetadata - | $(dirname "$0")/addKapitelFromCD_ffmetadata.sh "$1" "$2"
