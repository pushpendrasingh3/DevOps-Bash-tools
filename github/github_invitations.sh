#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2022-03-22 17:43:43 +0000 (Tue, 22 Mar 2022)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/github.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Lists / Accepts GitHub repo invitations

Any arguments given are assumed to be invitation IDs or repositories and those are accepted.
If the argument 'all' is given, accepts all invitations.

Useful to clear a bulk of invitations generated by automation code
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<id> <id2> ... ]"

help_usage "$@"

#min_args 1 "$@"

for (( page=1; page <= 100; page++)); do
    if ! output="$("$srcdir/github_api.sh" "/user/repository_invitations?page=$page&per_page=100")"; then
        echo "ERROR" >&2
        exit 1
    fi
    jq_debug_pipe_dump <<< "$output" |
    jq -r '.[] | select(.expired == false) | [.id, .repository.full_name] | @tsv'
    github_result_has_more_pages "$output" || break
done |
while read -r id owner_repo; do
    if [ $# -gt 0 ]; then
        for arg in "$@"; do
            if [ "$arg" = "all" ] ||
               [ "$arg" = "$id" ] ||
               [ "$arg" = "$owner_repo" ]; then
                timestamp "accepting invitation '$id' for repo '$owner_repo'"
                "$srcdir/github_api.sh" "/user/repository_invitations/$id" -X PATCH
                echo >&2
                continue
            fi
        done
    else
        printf '%s\t%s\n' "$id" "$owner_repo"
    fi
done
