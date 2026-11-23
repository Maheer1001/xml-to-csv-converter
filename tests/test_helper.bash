# Shared helpers for the bats suite.

REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
FIXTURES="$BATS_TEST_DIRNAME/fixtures"
export LC_ALL="${LC_ALL:-C.UTF-8}"

# Every test works in its own temp dir, because xml-to-csv.sh writes
# students.csv / faculty.csv into the current directory.
setup() {
	WORK="$BATS_TEST_TMPDIR/work"
	mkdir -p "$WORK"
	cd "$WORK"
}

# convert_fixture <fixture-dir> : copy the fixture's XML into $WORK and run
# the real script on it. Leaves bats' $status/$output set.
convert_fixture() {
	cp "$FIXTURES/$1"/*.xml "$WORK/"
	local xml
	xml="$(cd "$WORK" && ls *.xml)"
	run bash "$REPO_ROOT/xml-to-csv.sh" "$xml"
}

# Write an XML string to $WORK/<name> and convert it.
convert_string() {
	printf '%s' "$2" > "$WORK/$1"
	run bash "$REPO_ROOT/xml-to-csv.sh" "$1"
}

# assert_same_file <expected> <actual> : byte-for-byte, prints a diff on failure.
assert_same_file() {
	if ! diff -u "$1" "$2"; then
		echo "files differ: $1 vs $2" >&2
		return 1
	fi
}
