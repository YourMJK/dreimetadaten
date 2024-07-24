BASEDIR=$(dirname "$0")/..
BASEDIR=$(realpath --relative-to=. "$BASEDIR")

DBFILE=${DBFILE:-"$BASEDIR"/metadata/db.sqlite}
SQLFILE=${SQLFILE:-"$BASEDIR"/metadata/db.sql}
