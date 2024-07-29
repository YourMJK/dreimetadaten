#!/bin/bash

source $(dirname "$0")/.config.sh

if [ $# -lt 2 ]
then
	echo 'Add new "medium" to "hörspiel", read text in ffmetadata format from <input file>, add chapters as "track"s to "medium" and reference those as new "kapitel" appended to "hörspiel".'
	echo "Usage:   $(basename "$0") [--edit] (--id <hörspielID> | --nr <nummer> | --titel <titel>) <input file>"
	echo "Example: $(basename "$0") --nr 230 ffmetadata.txt"
	exit 1
fi

nextPosition() {
	# Find highest "position" in table "$1" and add 1
	sql "SELECT COALESCE(MAX(position),0)+1 FROM $1 WHERE hörspielID = $hoerspielID;" || exit 1
}

# Read arguments and setup new "medium" entry
if [ "$1" = "--edit" ]
then
	edit=1
	shift
fi
hoerspielID=$(parseArgID "$@") || exit 1
input="$3"
position=$(nextPosition "medium")
echo "Adding medium $position"
mediumID=$(sql "INSERT INTO medium(hörspielID,position,ripLog) VALUES($hoerspielID,$position,true); SELECT last_insert_rowid();") || exit 1
trackPosition=1
chapterPosition=$(nextPosition "kapitel")
chaptersFile=$(mktemp)

# Insert "track"/"kapitel" data
roundToMS() {
	echo "CAST(ROUND($1*1000*${timebase}.0) AS INT)"
}
saveChapter() {
	# Check for gaps between start chapter and end of previous chapter
	[ $start -eq $prevEnd ] || echo "Warning:  Gap between chapters (start $start vs. previous end $prevEnd)"
	prevEnd=$end
	# Format and insert data
	echo "Appending kapitel $chapterPosition: $title"
	[ -z "$title" ] && titel="null" || titel=$(sqlQuotedString "$title")
	dauer="$(roundToMS $end) - $(roundToMS $start)"
	sql "INSERT INTO track(mediumID,position,titel,dauer) VALUES($mediumID,$trackPosition,$titel,$dauer); INSERT INTO kapitel(trackID,hörspielID,position) VALUES(last_insert_rowid(),$hoerspielID,$chapterPosition);" || exit 1
}
# Add parsed chapters to temporary file (for optional manual editing)
addChapter() {
	printf "%s\t%s\t%s\t%s\n" "$timebase" "$start" "$end" "$title" >> "$chaptersFile"
}

# Parse ffmetadata
header=";FFMETADATA1"
chapter="[CHAPTER]"
parseValue() { echo "$line" | cut -d= -f2 ; }
prevEnd=0

while IFS= read -r line
do
	# Check for header in first line
	if [ -z $foundHeader ]
	then
		[ "$line" = "$header" ] || error "No ffmetadata header in input"
		foundHeader=1
	fi
	# Skip to first chapter entry
	if [ -z $foundChapters ]
	then
		[ "$line" = "$chapter" ] && foundChapters=1
		continue
	fi
	
	# Read chapter values
	case "$line" in
		TIMEBASE=*)
			timebase=$(parseValue)
			;;
		START=*)
			start=$(parseValue)
			;;
		END=*)
			end=$(parseValue)
			;;
		title=*)
			title=$(parseValue)
			;;
		"$chapter")
			# Finish chapter and begin next
			addChapter
			unset timebase start end title
			;;
	esac
done < "$input"

# Finish final chapter
addChapter

# Allow editing of chapter titles
if [ ! -z "$edit" ]
then
	# Split timestamps and titles to different temp files
	tsFile=$(mktemp)
	titlesFile=$(mktemp)
	cut -f-3 "$chaptersFile" > "$tsFile"
	cut -f4- "$chaptersFile" > "$titlesFile"
	# Open titles in $EDITOR and join with timestamps again
	editFile "$titlesFile" || error "Editing cancelled, aborting."
	paste "$tsFile" "$titlesFile" > "$chaptersFile"
	# Remove temp files
	rm "$titlesFile" "$tsFile"
fi

# Save chapters
while IFS=$'\t' read -r timebase start end title
do
	saveChapter
	((trackPosition++))
	((chapterPosition++))
done < "$chaptersFile"

# Remove temp file
rm "$chaptersFile"
