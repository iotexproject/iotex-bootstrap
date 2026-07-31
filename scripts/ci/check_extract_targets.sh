#!/usr/bin/env bash
#
# Assert that every snapshot extraction in this repo targets $IOTEX_HOME/data.
#
# The container mounts $IOTEX_HOME/data as /var/data and setup_fullnode.sh keys
# its install/upgrade detection off $IOTEX_HOME/data/chain.db, so a snapshot
# unpacked into $IOTEX_HOME itself leaves the mounted data directory empty and
# the node syncs from genesis. That is what happened when the snapshot URLs were
# split into core/gateway tarballs: all_in_one_*.sh was updated, the two setup
# scripts and the docs were not, and nothing caught it.
#
# This is a static check — no network, no downloads. It scans shell scripts and
# markdown for tar invocations in extract mode and requires each one to name an
# explicit destination under $IOTEX_HOME/data. Extractions unrelated to chain
# data are listed in ALLOWED below.
#
# Usage: scripts/ci/check_extract_targets.sh
set -uo pipefail

cd "$(dirname "$0")/../.."

# tar invoked in extract mode: `tar xvf`, `tar -xzf`, `tar -xf -`, ...
# Deliberately does not match `tar -tzf` (list) or `tar -czf` (create).
EXTRACT_RE='(^|[|;&(]|[[:space:]])tar[[:space:]]+-?[a-zA-Z-]*x'

# A destination under $IOTEX_HOME/data, with or without a trailing slash.
DEST_RE='(-C|--directory)[[:space:]]+\$(IOTEX_HOME|\{IOTEX_HOME\})/data/?([[:space:]]|$)'

# Extractions that have nothing to do with chain data.
ALLOWED=(
    'go1\.[0-9.]+\.linux-amd64\.tar\.gz'   # Go toolchain, archive-node.md
    'prometheus-[0-9]'                     # monitoring stack
    'cmake-[0-9]'                          # build tooling
    '\$\{1\}-\$\{2\}\.tar\.gz'             # get_systemstat.sh diagnostics bundle
)

isAllowed() {
    local line=$1 pattern
    for pattern in "${ALLOWED[@]}"; do
        if echo "$line" | grep -Eq "$pattern"; then
            return 0
        fi
    done
    return 1
}

failed=0
checked=0

# Only shell and markdown are in scope; those are the files node operators copy
# commands out of. Comment lines in shell scripts are skipped so that
# commented-out history does not have to be kept compliant.
#
# scripts/ci/ is excluded: it is tooling, not something anyone runs against a
# node, and this file quotes the correct tar form in its own failure message —
# without the exclusion the check reports itself.
while IFS= read -r file; do
    lineno=0
    while IFS= read -r line; do
        lineno=$((lineno + 1))

        case "$file" in
            *.sh)
                echo "$line" | grep -Eq '^[[:space:]]*#' && continue
                ;;
        esac

        echo "$line" | grep -Eq "$EXTRACT_RE" || continue
        isAllowed "$line" && continue

        checked=$((checked + 1))
        if echo "$line" | grep -Eq "$DEST_RE"; then
            echo "ok   $file:$lineno"
        else
            echo "FAIL $file:$lineno"
            echo "     $(echo "$line" | sed 's/^[[:space:]]*//')"
            failed=1
        fi
    done < "$file"
done < <(git ls-files '*.sh' '*.md' | grep -v '^scripts/ci/')

if [ $failed -ne 0 ]; then
    echo
    echo "Snapshot extractions must name their destination explicitly:"
    echo "    tar -xzf <tarball> -C \$IOTEX_HOME/data"
    echo
    echo "The tarballs are flat (chain-*.db at the archive root), \$IOTEX_HOME/data"
    echo "is what the container mounts as /var/data, and setup_fullnode.sh looks for"
    echo "\$IOTEX_HOME/data/chain.db to tell an upgrade from a fresh install."
    echo
    echo "If the extraction above is not chain data, add it to ALLOWED in $0."
    exit 1
fi

echo
echo "All $checked snapshot extractions target \$IOTEX_HOME/data."
