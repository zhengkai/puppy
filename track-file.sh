#!/bin/bash -e

FILE="${1:-game-server/app.js}"
if [ -z "$FILE" ]; then
	exit;
fi

DIR="$(dirname "$(readlink -f "$0")")" && cd "$DIR" || exit 1
. ./config.sh

HISTORY_FILE="${DIR}/tmp/tracked-file"

export GIT_DIR="repo"

HASH=$(git log -n 1 --abbrev=12 --pretty=format:"%h" -- "$FILE")
if [ -z "$HASH" ]; then
	>&2 echo file "$FILE" not found
	exit
fi

TRACK_HOOK="${DIR}/hooks/track-file"

FIND=$(grep -F "$FILE " "$HISTORY_FILE" | head -n 1 || :)
if [ -n "$FIND" ]; then
	PREV_HASH="${FIND##* }"
	if [ "$PREV_HASH" == "$HASH" ]; then
		echo "$FILE no change"
		exit
	fi

	ESCAPED_REPLACE=$(printf '%s\n' "$FILE" | sed -e 's/[\/&]/\\&/g')
	sed -i "/^$ESCAPED_REPLACE/d" "$HISTORY_FILE"

	if [ -x "$TRACK_HOOK" ]; then
		"$TRACK_HOOK" "$FILE" "$PREV_HASH" "$HASH"
	else
		echo "$FILE changed: $PREV_HASH to $HASH"
	fi
fi

echo "$FILE $HASH" >> "$HISTORY_FILE"
