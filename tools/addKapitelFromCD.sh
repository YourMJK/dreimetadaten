#!/bin/bash

source $(dirname "$0")/.config.sh

if [ $# -lt 3 ]
then
	echo 'Add new "medium" to "hörspiel", read embedded chapters in <audio file>, add chapters as "track"s to "medium" and reference those as new "kapitel" appended to "hörspiel".'
	echo "Usage:   $(basename "$0") (--id <hörspielID> | --nr <nummer> | --titel <titel>) <audio file>"
	echo "Example: $(basename "$0") --nr 230 CD.m4a"
	exit 1
fi

# Saving ffmpeg output in variable because ffmpeg doesn't seem to support process substitution with STDOUT as output
ffmetadata=$(ffmpeg -loglevel error -i "$3" -f ffmetadata -)
$(dirname "$0")/addKapitelFromCD_ffmetadata.sh --edit "$1" "$2" <(echo "$ffmetadata")
