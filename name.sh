#!/bin/bash

# 將诸如分支名等格式化成安全的文件名

BRANCH="$1"
if [ -z "$BRANCH" ]; then
	exit;
fi
echo "${BRANCH,,}" | sed -E 's#[^0-9a-z]#-#g' | sed -E 's#\-+#-#g' | sed -E 's#^-##g' | sed -E 's#-$##g'
