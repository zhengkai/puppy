#!/bin/bash

DIR="$(dirname "$(readlink -f "$0")")" && cd "$DIR" || exit 1

rm tmp/conflict-*.txt 2>/dev/null || :
FIRST_CONFLICT="1"
CONFLICT_HOOK="${DIR}/hooks/conflict"
mapfile -t LIST < <(find tmp -name "diff-*.txt" | sort)
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

		FILE="${DIR}/tmp/conflict-${FA:9:-4}_${FB:9:-4}.txt"

		(
			echo "$BA"
			echo "$BB"
			echo "$SAME"
		) > "$FILE"

		DIFF=""
		while read -r LINE; do
			STAT=$(git --git-dir=repo diff --numstat "${BA}..${BB}" -- "$LINE")
			if [[ -n "$STAT" ]]; then
				if [ -n "$FIRST_CONFLICT" ]; then
					FIRST_CONFLICT=""
					echo
					echo branch conflict:
				fi
				CNT="$(echo "$STAT" | cut -d"	" -f1)"
				((CNT+=$(echo "$STAT" | cut -d"	" -f2)))
				DIFF="1"
				echo "$LINE:$CNT" >> "$FILE"
			fi
		done < <(diff -u "$FA" "$FB" | grep -P '^ ' | sed -e 's#^ ##')

		if [ -z "$DIFF" ]; then
			rm "$FILE"
			continue
		fi

		if [ -x "$CONFLICT_HOOK" ]; then
			"$CONFLICT_HOOK" < "$FILE"
		fi

	done
done
