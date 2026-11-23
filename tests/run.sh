#!/usr/bin/env bash
# Runs the test suite with bats-core.
# Uses `bats` from PATH if installed; otherwise clones a pinned bats-core
# into tests/.bats-core (git-ignored, local to this repo, nothing global).
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BATS_VERSION="v1.11.1"

if command -v bats >/dev/null 2>&1; then
	bats_bin="bats"
else
	if [ ! -x "$here/.bats-core/bin/bats" ]; then
		echo "bats not found on PATH; fetching bats-core $BATS_VERSION into tests/.bats-core" >&2
		git -c advice.detachedHead=false clone --quiet --depth 1 --branch "$BATS_VERSION" \
			https://github.com/bats-core/bats-core.git "$here/.bats-core"
	fi
	bats_bin="$here/.bats-core/bin/bats"
fi

export LC_ALL="${LC_ALL:-C.UTF-8}"
exec "$bats_bin" "$@" "$here"
