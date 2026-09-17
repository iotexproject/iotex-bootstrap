#!/usr/bin/env bash
#
# Assert that the published snapshot tarballs are flat, i.e. their members sit
# at the archive root (chain-*.db, bloomfilter.index.db, ...) with no leading
# data/ directory.
#
# Everything in this repo that unpacks a snapshot does so with
# `-C $IOTEX_HOME/data`, which is only correct while that holds. If the
# publishing side ever goes back to wrapping the contents in a data/ directory,
# those extractions would silently produce $IOTEX_HOME/data/data/... and a node
# that syncs from genesis. Nothing in this repo would otherwise notice.
#
# Only the first megabyte of each tarball is fetched: a tar member header is the
# first 512 bytes, so that is enough to read the first member name. gzip and tar
# both complain about the truncated stream after that, which is expected and
# ignored.
#
# Usage: scripts/ci/check_snapshot_layout.sh
#        SNAPSHOT_URLS="url1 url2" scripts/ci/check_snapshot_layout.sh
set -uo pipefail

if [ -n "${SNAPSHOT_URLS:-}" ]; then
    # shellcheck disable=SC2206
    URLS=($SNAPSHOT_URLS)
else
    URLS=(
        "https://t.iotex.me/mainnet-data-snapshot-core-latest"
        "https://t.iotex.me/mainnet-data-snapshot-gateway-latest"
        "https://t.iotex.me/testnet-data-snapshot-core-latest"
        "https://t.iotex.me/testnet-data-snapshot-gateway-latest"
    )
fi

RANGE_BYTES=1048575
ATTEMPTS=3
failed=0

# Lists the members of a remote tarball that are readable from its first
# megabyte, with the archive's own root entry ("." / "./") dropped — that entry
# is present or absent depending on how the archive was created and says nothing
# about the layout, but taking it as "the first member" would mask a payload
# nested under data/.
#
# -L is required: t.iotex.me redirects to the object storage host, and without
# it curl returns an empty redirect body that decompresses to nothing.
leadingMembers() {
    local url=$1 out=$2
    curl -sSL --max-time 120 -r "0-${RANGE_BYTES}" "$url" -o "$out" || return 1
    [ -s "$out" ] || return 1
    gzip -dc "$out" 2>/dev/null | tar -tf - 2>/dev/null \
        | sed 's|^\./||' \
        | grep -v '^\.\?/\?$'
}

for url in "${URLS[@]}"; do
    tmp=$(mktemp)
    members=""
    for attempt in $(seq 1 $ATTEMPTS); do
        members=$(leadingMembers "$url" "$tmp")
        [ -n "$members" ] && break
        if [ "$attempt" -lt "$ATTEMPTS" ]; then
            echo "  retrying $url ($attempt/$ATTEMPTS)..." >&2
            sleep 5
        fi
    done
    size=$(wc -c < "$tmp" | tr -d ' ')
    rm -f "$tmp"

    if [ -z "$members" ]; then
        # Treated as a failure rather than a skip: an empty read is exactly what
        # a broken redirect or an HTML error page looks like, and silently
        # passing on it would defeat the purpose of the check.
        echo "FAIL $url"
        echo "     could not read any member name (downloaded ${size} bytes)"
        failed=1
        continue
    fi

    nested=$(echo "$members" | grep '^data/' | head -1)
    if [ -n "$nested" ]; then
        echo "FAIL $url"
        echo "     member '$nested' sits under data/ — the tarball is no longer flat."
        echo "     Snapshot extractions in this repo pass '-C \$IOTEX_HOME/data'"
        echo "     and would now nest the payload one level too deep."
        failed=1
    else
        echo "ok   $url -> $(echo "$members" | head -1)"
    fi
done

if [ $failed -ne 0 ]; then
    echo
    echo "Snapshot layout changed. Update the extraction targets in scripts/ and"
    echo "the docs together, then adjust this check."
    exit 1
fi

echo
echo "All snapshot tarballs are flat."
