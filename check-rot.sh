#!/bin/bash -e

# 检查指定分支最后一次 rebase master 的时间

BRANCH="$1"
if [ -z "$BRANCH" ]; then
	exit;
fi

DIR="$(dirname "$(readlink -f "$0")")" && cd "$DIR" || exit 1
. ./config.sh

export GIT_DIR="repo"

# NAME="$(echo "${BRANCH,,}" | sed -E 's#[^0-9a-z]#-#g' | sed -E 's#\-+#-#g' | sed -E 's#^-##g' | sed -E 's#-$##g' )"

COMMIT=$(git merge-base "$BRANCH" "$MAIN_BRANCH")
TS=$(git show --no-patch --pretty=format:"%ct" "$COMMIT")
TR=$(git show --no-patch --pretty=format:"%cr" "$COMMIT")

((TS=$(date +%s)-TS))

if [[ "$TS" -lt "$ROT_TIME" ]]; then
	exit
fi

echo "${BRANCH}: $TR"

ROT_HOOK="${DIR}/hooks/rot"
if [ -x "$ROT_HOOK" ]; then
	"$ROT_HOOK" "$BRANCH" "$TS"
fi
