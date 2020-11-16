#!/bin/bash -e

# 检查指定分支最后一次 rebase master 的时间

BRANCH="$1"
if [ -z "$BRANCH" ]; then
	exit;
fi

DIR="$(dirname "$(readlink -f "$0")")" && cd "$DIR" || exit 1
. ./config.sh

export GIT_DIR="repo"

NAME="$("${DIR}/name.sh" "$BRANCH")"

COMMIT=$(git merge-base "$BRANCH" "$MAIN_BRANCH")
SEC=$(git show --no-patch --pretty=format:"%ct" "$COMMIT")
TR=$(git show --no-patch --pretty=format:"%cr" "$COMMIT")

NOW=$(date +%s)
((SEC=NOW-SEC))

if [[ "$SEC" -lt "$ROT_TIME" ]]; then
	exit
fi

echo "${BRANCH}: $TR"

TIME_FILE="${DIR}/tmp/time-rot-${NAME}"
touch "$TIME_FILE"

HOOK_TIME=$(cat "$TIME_FILE" || echo 1)
if [[ "$HOOK_TIME" -gt "$NOW" ]]; then
	exit
fi
((HOOK_TIME=NOW+ROT_TIME))
echo "$HOOK_TIME" > "$TIME_FILE"

ROT_HOOK="${DIR}/hooks/rot"
if [ -x "$ROT_HOOK" ]; then
	"$ROT_HOOK" "$BRANCH" "$SEC"
fi
