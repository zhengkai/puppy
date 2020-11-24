#!/bin/bash -e

FILE="${1:-game-server/app.js}"
if [ -z "$FILE" ]; then
	exit;
fi

DIR="$(dirname "$(readlink -f "$0")")" && cd "$DIR" || exit 1
. ./config.sh

if [ ! -e list-track.txt ]; then
	exit
fi

export GIT_DIR="repo"

CURRENT_COMMIT=$(git log -n 1 --abbrev=12 --pretty=format:"%h")
PREV_COMMIT_FILE="${DIR}/tmp/track-prev-commit"
PREV_COMMIT=$(cat "$PREV_COMMIT_FILE" 2>/dev/null || :)

if [ -z "$PREV_COMMIT" ]; then
	echo "$CURRENT_COMMIT" > "$PREV_COMMIT_FILE"
	exit
fi
if [ "$PREV_COMMIT" == "$CURRENT_COMMIT" ]; then
	exit
fi

TRACK_CHANGE_FILE="${DIR}/tmp/track-change"
cat /dev/null > "$TRACK_CHANGE_FILE"

while read -r LINE
do

	if [ -z "$LINE" ]; then
		continue
	fi

	git diff --name-only "$CURRENT_COMMIT" "$PREV_COMMIT" -- "$LINE" | while read -r FILE; do
		AUTHOR=$(git log -n 1 --abbrev=12 --date="format:%Y-%m-%d %H:%M:%S" --pretty=format:"%cn, %cd" -- "$FILE")
		echo "$FILE ( $AUTHOR )" >> "$TRACK_CHANGE_FILE"
	done

done < list-track.txt

echo "$CURRENT_COMMIT" > "$PREV_COMMIT_FILE"

if [ ! -s "$TRACK_CHANGE_FILE" ]; then
	exit
fi

NUM=$(wc -l < "$TRACK_CHANGE_FILE")
if [ "$NUM" == 1 ]; then
	NUM="$NUM file"
else
	NUM="$NUM files"
fi
echo
echo "track: $NUM changed"
echo

HOOK="${DIR}/hooks/track"
if [ -x "$HOOK" ]; then
	"$HOOK" < "$TRACK_CHANGE_FILE"
fi
