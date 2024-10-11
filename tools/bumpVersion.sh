#!/bin/bash

source $(dirname "$0")/.config.sh

if [ $# -lt 1 ]
then
	echo 'Bump semantic version number in database one higher.'
	echo "Usage:   $(basename "$0") (major | minor | patch)"
	echo "Example: $(basename "$0") patch"
	exit 1
fi

case "$1" in
	major)
		new="major+1,0,0"
		;;
	minor)
		new="major,minor+1,0"
		;;
	patch)
		new="major,minor,patch+1"
		;;
	*)
		error "Invalid semantic version component \"$1\""
		;;
esac

sql "INSERT INTO version(major,minor,patch)
     SELECT $new FROM version ORDER BY date DESC LIMIT 1
     RETURNING major || '.' || minor || '.' || patch"
