#!/usr/bin/env bats
# Setup check: runs the real scripts end to end, the way the README does, in a
# temp dir, and compares against committed expected output. If these pass,
# your Bash / GNU grep / sed / awk / locale toolchain is wired up correctly.

load test_helper

@test "toolchain: GNU grep with -P (PCRE) is available" {
	run bash -c "echo '<a>' | grep -oP '(?<=<)[^<>]+(?=>)'"
	[ "$status" -eq 0 ]
	[ "$output" = "a" ]
}

@test "setup check: bundled sample students.xml -> expected students.csv and names" {
	cp "$FIXTURES/students-basic/students.xml" .
	run bash "$REPO_ROOT/xml-to-csv.sh" students.xml
	[ "$status" -eq 0 ]
	assert_same_file "$FIXTURES/students-basic/expected.csv" students.csv
	run bash "$REPO_ROOT/unique-names.sh" students.csv names.txt
	[ "$status" -eq 0 ]
	assert_same_file "$FIXTURES/students-basic/expected-names.txt" names.txt
}

# The full datasets: regenerate and compare with the CSVs committed in the
# repo root. --strip-trailing-cr tolerates CRLF checkouts on Windows.

@test "setup check: full students.xml reproduces committed students.csv" {
	cp "$REPO_ROOT/students.xml" .
	run bash "$REPO_ROOT/xml-to-csv.sh" students.xml
	[ "$status" -eq 0 ]
	diff -q --strip-trailing-cr "$REPO_ROOT/students.csv" students.csv
}

@test "setup check: full faculty.xml reproduces committed faculty.csv" {
	cp "$REPO_ROOT/faculty.xml" .
	run bash "$REPO_ROOT/xml-to-csv.sh" faculty.xml
	[ "$status" -eq 0 ]
	diff -q --strip-trailing-cr "$REPO_ROOT/faculty.csv" faculty.csv
}

@test "setup check: unique-names.sh reproduces committed students.txt" {
	run bash "$REPO_ROOT/unique-names.sh" "$REPO_ROOT/students.csv" students.txt
	[ "$status" -eq 0 ]
	diff -q --strip-trailing-cr "$REPO_ROOT/students.txt" students.txt
}
