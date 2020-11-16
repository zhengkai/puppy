# shellcheck disable=SC2034

REPO_URL="git@github.com:foo/bar.git"
MAIN_BRANCH="master"
WATCH_BRANCH="^(foo|bar)/"

# 腐烂 报警时间：超过一周没 rebase
ROT_TIME=604800

# 冲突 报警间隔时间
CONFLICT_TIME=86400
