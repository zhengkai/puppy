#!/bin/bash -e

DIR="$(dirname "$(readlink -f "$0")")" && cd "$DIR" || exit 1
TMP="${DIR}/tmp"

mkdir -p tmp

. ./config.sh

# 更新仓库

if [ ! -d repo ]; then
	git clone --mirror "$REPO_URL" repo
fi
echo 'git fetch ...'
git --git-dir=repo fetch --prune
echo 'done'

# 生成要检查的分支

BRANCH_FILE="${TMP}/branch.txt"
touch list-ignore.txt
cat /dev/null > "$BRANCH_FILE"
git --git-dir=repo branch | sed 's#^. ##g' | grep -P "$WATCH_BRANCH" | while read -r LINE; do

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

# branch conflict

rm tmp/diff-*.txt 2>/dev/null|| :
xargs -L 1 "${DIR}/diff-branch.sh" < "$BRANCH_FILE" | sed -e 's#^#    #'

mapfile -t LIST < <(ls tmp/diff-*.txt)

LEN=${#LIST[@]}

for (( i = LEN - 1; i > 1; i-- )); do
	for (( j = i - 1; j > 0; j-- )); do

		FA="${LIST[$i]}"
		FB="${LIST[$j]}"

		SAME=$(diff -u "$FA" "$FB" | grep -c -P '^ ' || :)
		if [[ "$SAME" -lt 1 ]]; then
			continue
		fi

		BA=$(head -n 1 "$FA")
		BB=$(head -n 1 "$FB")

		echo
		echo "$BA $BB"
		echo "$SAME"
		diff -u "$FA" "$FB" | grep -P '^ ' | sed -e 's#^ #    #'

	done
done

# echo "$len" "${list[@]}"
