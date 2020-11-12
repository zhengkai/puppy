#!/bin/bash -e

BRANCH="${1:-bbaiyang/machine92}"
if [ -z "$BRANCH" ]; then
	exit;
fi

DIR="$(dirname "$(readlink -f "$0")")" && cd "$DIR" || exit 1
. ./config.sh

NAME="$(echo "${BRANCH,,}" | sed -E 's#[^0-9a-z]#-#g' | sed -E 's#\-+#-#g' | sed -E 's#^-##g' | sed -E 's#-$##g' )"

FILE="${DIR}/tmp/diff-${NAME}.txt"

FORK_POINT=$(git --git-dir=repo merge-base "$BRANCH" "$MAIN_BRANCH")

echo "$BRANCH" > "$FILE"

git --git-dir=repo diff --name-only "${BRANCH}..${FORK_POINT}" >> "$FILE"

LINE=$(wc -l < "$FILE")
if [[ "$LINE" -le 1 ]]; then
	rm "$FILE"
	exit
fi

echo "$BRANCH" "$(wc -l < "$FILE")"
