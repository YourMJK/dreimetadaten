#!/bin/bash

source $(dirname "$0")/.config.sh

if [ $# -lt 2 ]
then
	echo 'Add first four "sprechrolle" from last "serie" entry to "hörspiel", read sprecher TSV from stdin, look up "rolle" and "person" by name and add them as "sprechrolle" as well.'
	echo "Usage:   $(basename "$0") [--dry-run] [--no-copy | --copy-from <hörspielID> <count>] (--id <hörspielID> | --nr <nummer> | --titel <titel>) [<input file> = STDIN]"
	echo "Example: $(basename "$0") --nr 230 sprecher.tsv"
	exit 1
fi

# Read arguments and setup new "medium" entry
if [[ "$1" == "--dry-run" ]]
then dryrun=true ; shift
else dryrun=false
fi
$dryrun && echo "Running in dry-run mode ..."

case "$1" in
	--no-copy)
		shift
		;;
	--copy-from)
		previousHoerspielID=$2
		previousCount=$3
		shift 3
		;;
	*)
		previousHoerspielID=$(sql "SELECT hörspielID FROM serie NATURAL JOIN hörspiel WHERE unvollständig = false ORDER BY nummer DESC LIMIT 1;") || exit 1
		previousCount=4
		;;
esac

hoerspielID=$(parseArgID "$@") || exit 1
input=${3:-/dev/stdin}
sprechrollePosition=$(sql "SELECT COALESCE(MAX(position),0)+1 FROM sprechrolle WHERE hörspielID = $hoerspielID;") || exit 1

addSprechrolle() {
	echo -e "Sprechrolle $sprechrollePosition:\t\"$rolle\"\t\"$sprecher\""
	$dryrun || sql "INSERT INTO sprechrolle(hörspielID,rolleID,position) VALUES($hoerspielID,$rolleID,$sprechrollePosition); INSERT INTO spricht(sprechrolleID,personID,position) VALUES(last_insert_rowid(),$personID,1);" || exit 1
}
warnNew() {
	color=$(tput setaf 11)
	bold=$(tput bold)
	reset=$(tput sgr0)
	echo "${color}> NEW $1: \"${bold}$2${reset}${color}\"${reset}"
}

# Add first four entries from previous "hörspiel"
if [ ! -z $previousHoerspielID ]
then
	echo "Copying first $previousCount from hörspielID $previousHoerspielID ..."
	while IFS=$'\t' read -r rolleID personID rolle sprecher
	do
		addSprechrolle
		((sprechrollePosition++))
	done < <(sql ".mode tabs --quote off" "SELECT sr.rolleID, s.personID, r.name, p.name FROM sprechrolle sr, spricht s, rolle r, person p WHERE sr.hörspielID = $previousHoerspielID AND sr.sprechrolleID = s.sprechrolleID AND r.rolleID = sr.rolleID AND p.personID = s.personID ORDER BY sr.position LIMIT $previousCount;") || exit 1
fi

# Parse TSV
while IFS= read -r line
do
	rolle=$(echo "$line" | cut -s -f1)
	sprecher=$(echo "$line" | cut -s -f2)
	if [ -z "$rolle" ] || [ -z "$sprecher" ]
	then
		echo "(Skipping invalid line \"$line\")"
		continue
	fi
	
	# Find "rolle" by name or create new
	rolleString=$(sqlQuotedString "$rolle")
	rolleID=$(sql "SELECT rolleID FROM rolle WHERE name = $rolleString;") || exit 1
	if [ -z $rolleID ]
	then
		warnNew rolle "$rolle"
		$dryrun || rolleID=$(sql "INSERT INTO rolle(name) VALUES($rolleString); SELECT last_insert_rowid();") || exit 1
	fi
	
	# Find "person" by name or create new
	sprecherString=$(sqlQuotedString "$sprecher")
	personID=$(sql "SELECT personID FROM person WHERE name = $sprecherString;") || exit 1
	if [ -z $personID ]
	then
		warnNew person "$sprecher"
		$dryrun || personID=$(sql "INSERT INTO person(name) VALUES($sprecherString); SELECT last_insert_rowid();") || exit 1
	fi
	
	addSprechrolle
	((sprechrollePosition++))
done < "$input"
