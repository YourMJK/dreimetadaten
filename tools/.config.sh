BASEDIR=$(dirname "$0")/..
BASEDIR=$(realpath --relative-to=. "$BASEDIR")

DBFILE=${DBFILE:-"$BASEDIR"/metadata/db.sqlite}
SQLFILE=${SQLFILE:-"$BASEDIR"/metadata/db.sql}

DEBUG=${DEBUG:-0}
EDITOR=${EDITOR:-"nano -l"}

error() {
	echo "Error${1+:  }$1" >&2
	exit 1
}

sql() {
	[ $DEBUG -eq 1 ] && echo "$(tput setaf 8)> $*$(tput sgr0)" >&2
	sqlite3 -batch "$DBFILE" "$@"
}

sqlQuotedString() {
	escaped=$(echo "$1" | sed "s/'/''/")
	echo "'$escaped'"
}

parseArgID() {
	case "$1" in
		--id)
			hoerspielID=$2
			;;
		--nr)
			hoerspielID=$(sql "SELECT hörspielID FROM serie WHERE nummer = $2;") || return 1
			;;
		--titel)
			titel=$(sqlQuotedString "$2")
			hoerspielID=$(sql "SELECT hörspielID FROM hörspiel WHERE titel LIKE $titel LIMIT 1;") || return 1
			;;
		*)
			error "Invalid identification method \"$1\". Use --id, --nr or --titel."
			;;
	esac
	[ -z $hoerspielID ] && error "Couldn't identify \"hörspiel\" from the given arguments. Try a different method."
	echo $hoerspielID
}

editFile() {
	$EDITOR "$1"
}
