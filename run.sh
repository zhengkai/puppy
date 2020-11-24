#!/bin/bash

DIR="$(dirname "$(readlink -f "$0")")" && cd "$DIR" || exit 1
TMP="${DIR}/tmp"

mkdir -p tmp
touch list-ignore.txt
TRACK_FILE="list-track.txt"
touch "$TRACK_FILE"

LOCK_FILE="${TMP}/lock-run"
exec 200>"$LOCK_FILE"
flock -n 200 || {
	echo "$LOCK_FILE locked"
	exit
}

. ./config.sh

# 更新仓库

if [ ! -d repo ]; then
	git clone --mirror "$REPO_URL" repo
fi
echo 'git fetch ...'
git --git-dir=repo fetch -f --prune
echo 'done'

export GIT_DIR="repo"

# track file

if [ -s "$TRACK_FILE" ]; then
	./track.sh
fi

# 生成要检查的分支

BRANCH_FILE="${TMP}/branch.txt"
cat /dev/null > "$BRANCH_FILE"
git branch | sed 's#^. ##g' | grep -P "$WATCH_BRANCH" | while read -r LINE; do

	# 分支忽略列表
	IGNORE=$(grep -Fx "$LINE" list-ignore.txt || :)
	if [ -n "$IGNORE" ]; then
		continue
	fi

	echo "$LINE" >> "$BRANCH_FILE"
done

echo
echo branch:
sed -e 's/^/    /' "$BRANCH_FILE"

# check rot

echo
echo check rot:
xargs -L 1 "${DIR}/check-rot.sh" < "$BRANCH_FILE" | sed -e 's#^#    #'

# diff branch

echo
echo "branch diff with $MAIN_BRANCH:"

rm tmp/diff-*.txt 2>/dev/null || :
xargs -L 1 "${DIR}/diff-branch.sh" < "$BRANCH_FILE" | sed -e 's#^#    #'

# branch conflict

"${DIR}/branch-conflict.sh"

flock -u 200
