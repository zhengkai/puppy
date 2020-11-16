#!/bin/bash

DIR="$(dirname "$(readlink -f "$0")")" && cd "$DIR" || exit 1
. ./config.sh

rm tmp/conflict-*.txt 2>/dev/null || :
FIRST_CONFLICT="1"
CONFLICT_HOOK="${DIR}/hooks/conflict"
mapfile -t LIST < <(find tmp -name "diff-*.txt" | sort -r)
LEN=${#LIST[@]}
NOW=$(date +%s)
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

		NAME="${FA:9:-4}_${FB:9:-4}"

		FILE="${DIR}/tmp/conflict-${NAME}.txt"

		(
			echo "$BA"
			echo "$BB"
		) > "$FILE"

		FILE_NUM=0
		while read -r LINE; do
			STAT=$(git --git-dir=repo diff --numstat "${BA}..${BB}" -- "$LINE")
			if [[ -n "$STAT" ]]; then
				if [ -n "$FIRST_CONFLICT" ]; then
					FIRST_CONFLICT=""
					echo
					echo branch conflict:
				fi
				CNT="$(echo "$STAT" | cut -d"	" -f1 | sed 's#-#0#')"
				((CNT+=$(echo "$STAT" | cut -d"	" -f2 | sed 's#-#0#')))
				((FILE_NUM++))
				echo "$LINE:$CNT" >> "$FILE"
			fi

		done < <(diff -u "$FA" "$FB" | grep -P '^ ' | sed -e 's#^ ##')

		if [[ "$FILE_NUM" -lt 1 ]]; then
			rm "$FILE"
			continue
		fi

		echo
		echo "branch A: $BA"
		echo "branch B: $BB"
		echo "files ( $FILE_NUM ):"
		tail -n "+3" "$FILE" | sed -e 's#^#    #'

		if [ ! -x "$CONFLICT_HOOK" ]; then
			continue
		fi

		TIME_FILE="${DIR}/tmp/time-conflict-${NAME}"
		touch "$TIME_FILE"
		HOOK_TIME=$(cat "$TIME_FILE" || echo 1)
		if [[ "$HOOK_TIME" -gt "$NOW" ]]; then
			continue
		fi
		((HOOK_TIME=NOW+CONFLICT_TIME))

		echo "$HOOK_TIME" > "$TIME_FILE"

		"$CONFLICT_HOOK" < "$FILE"

	done
done
