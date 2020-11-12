#!/bin/bash -e

# 检查指定分支最后一次 rebase master 的时间

BRANCH="${1:-baiyang/machine92}"
if [ -z "$BRANCH" ]; then
	exit;
fi

DIR="$(dirname "$(readlink -f "$0")")" && cd "$DIR" || exit 1
. ./config.sh

# NAME="$(echo "${BRANCH,,}" | sed -E 's#[^0-9a-z]#-#g' | sed -E 's#\-+#-#g' | sed -E 's#^-##g' | sed -E 's#-$##g' )"

COMMIT=$(git --git-dir=repo merge-base "$BRANCH" "$MAIN_BRANCH")
TS=$(git --git-dir=repo show --no-patch --pretty=format:"%ct" "$COMMIT")
TR=$(git --git-dir=repo show --no-patch --pretty=format:"%cr" "$COMMIT")

((TS=$(date +%s)-TS))

if [[ "$TS" -lt "$ROT_TIME" ]]; then
	exit
fi

echo "$BRANCH : $TR"
