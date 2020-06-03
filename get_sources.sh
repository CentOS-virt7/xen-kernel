#!/bin/bash
set -e

source sources.cfg
echo "Checking Linux $LINUX_VERSION release tarball"
if [[ ! -e SOURCES/$LINUX_RELEASE_FILE ]] ; then
    wget -P SOURCES/ $LINUX_RELEASE_BASE/$LINUX_RELEASE_FILE || exit 1
fi
if [[ ! -e SOURCES/$LINUX_RELEASE_FILE_SIG ]]; then
    wget -P SOURCES/ $LINUX_RELEASE_BASE/$LINUX_RELEASE_FILE_SIG || exit 1
fi
# Signature is on uncompressed image
echo "Uncompressing release file and checking signature"
xz -cd SOURCES/$LINUX_RELEASE_FILE | gpg2 --status-fd 1 --verify SOURCES/$LINUX_RELEASE_FILE_SIG - \
    | grep -q "GOODSIG ${LINUX_KEY}" || exit 1

# Check that we've got the expected Linux version
shasums=$(curl -sL https://www.kernel.org/pub/linux/kernel/v${LINUX_VERSION%%.*}.x/sha256sums.asc)
# Check against autosigner@kernel.org keys
gpg2 --status-fd=1 --verify - <<<"$shasums" | \
    grep -q -E '^\[GNUPG:\] GOODSIG 632D3A06589DA6B1' || exit 1

grep -E "^[0-9a-f]{64}  $LINUX_RELEASE_FILE$" <<<"$shasums" | \
    (cd SOURCES; sha256sum -c -) || exit 1

echo "All sources present."
