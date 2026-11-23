#!/usr/bin/env bats
# Behaviour of unique-names.sh.

load test_helper

@test "unique-names: sorted, de-duplicated first column, header skipped" {
	run bash "$REPO_ROOT/unique-names.sh" "$FIXTURES/students-basic/expected.csv" names.txt
	[ "$status" -eq 0 ]
	assert_same_file "$FIXTURES/students-basic/expected-names.txt" names.txt
}

@test "unique-names: sorts unsorted input and drops repeats" {
	printf 'name,x\nCarol,1\nAlice,2\nBob,3\nAlice,4\n' > in.csv
	run bash "$REPO_ROOT/unique-names.sh" in.csv out.txt
	[ "$status" -eq 0 ]
	[ "$(cat out.txt)" = "$(printf 'Alice\nBob\nCarol')" ]
}

@test "unique-names: header-only input gives an empty file" {
	printf 'name,x\n' > in.csv
	run bash "$REPO_ROOT/unique-names.sh" in.csv out.txt
	[ "$status" -eq 0 ]
	[ ! -s out.txt ]
}
