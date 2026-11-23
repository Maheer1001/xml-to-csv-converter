#!/usr/bin/env bats
# Behaviour of xml-to-csv.sh on small, hand-written fixtures.
# Tests labelled "limitation" pin down what the script does today in cases it
# was never designed for, so any change to that behaviour is deliberate.

load test_helper

# --- faculty mode (flat, 4 fields per record) ---------------------------

@test "faculty: flat records convert to the expected CSV" {
	convert_fixture faculty-basic
	[ "$status" -eq 0 ]
	assert_same_file "$FIXTURES/faculty-basic/expected.csv" faculty.csv
}

@test "faculty: header is built from the tag names" {
	convert_fixture faculty-basic
	[ "$(head -n 1 faculty.csv)" = "faculty,building,room,capacity" ]
}

@test "faculty: repeated records give one row each, duplicates kept" {
	convert_fixture faculty-basic
	[ "$(tail -n +2 faculty.csv | wc -l)" -eq 3 ]
	[ "$(grep -c '^Faculty of Art,B59,' faculty.csv)" -eq 2 ]
}

@test "faculty: any input not named students.xml is treated as faculty data" {
	cp "$FIXTURES/faculty-basic/faculty.xml" rooms.xml
	run bash "$REPO_ROOT/xml-to-csv.sh" rooms.xml
	[ "$status" -eq 0 ]
	[ ! -e rooms.csv ]
	assert_same_file "$FIXTURES/faculty-basic/expected.csv" faculty.csv
}

@test "faculty: CRLF input gives LF-only output" {
	sed 's/$/\r/' "$FIXTURES/faculty-basic/faculty.xml" > faculty.xml
	run bash "$REPO_ROOT/xml-to-csv.sh" faculty.xml
	[ "$status" -eq 0 ]
	run grep -c $'\r' faculty.csv
	[ "$output" = "0" ]
	assert_same_file "$FIXTURES/faculty-basic/expected.csv" faculty.csv
}

@test "faculty: quotes and entities pass through unchanged (no CSV quoting, no entity decoding)" {
	convert_fixture faculty-special-chars
	[ "$(sed -n 2p faculty.csv)" = 'Faculty of Art, Design,B "59",R&amp;D Lab,240' ]
}

@test "faculty limitation: commas inside values are neither removed nor quoted" {
	convert_fixture faculty-special-chars
	# "Faculty of Art, Design" splits into two columns: 5 fields instead of 4.
	[ "$(sed -n 2p faculty.csv | awk -F, '{print NF}')" -eq 5 ]
}

@test "faculty: attribute values are dropped, element text is kept" {
	convert_fixture faculty-attributes
	[ "$(sed -n 2p faculty.csv)" = "Faculty of Art,B59,R1000,240" ]
}

@test "faculty limitation: an attribute in the first record corrupts the header" {
	convert_fixture faculty-attributes
	[ "$(head -n 1 faculty.csv)" = 'faculty,building,room accessible="yes",room' ]
}

@test "faculty limitation: an empty field is dropped, shifting later columns" {
	convert_fixture faculty-missing-field
	[ "$(sed -n 2p faculty.csv)" = "Faculty of Art,B59,R1000,240" ]
	# <room></room> is deleted, so the last row is short and has no newline.
	[ "$(sed -n 3p faculty.csv)" = "Faculty of Law,B4,30," ]
}

# --- students mode (19 fields, 2-line address) ---------------------------

@test "students: records convert to the expected CSV" {
	convert_fixture students-basic
	[ "$status" -eq 0 ]
	assert_same_file "$FIXTURES/students-basic/expected.csv" students.csv
}

@test "students: header lists all 19 fields in order" {
	convert_fixture students-basic
	[ "$(head -n 1 students.csv)" = "student_name,student_id,student_email,programme,year,address,contact,module_id,module_name,module_leader,lecturer1,lecturer2,faculty,building,room,exam_mark,coursework1,coursework2,coursework3" ]
}

@test "students: every row has exactly 19 fields" {
	convert_fixture students-basic
	run awk -F, 'NF != 19 {print NR": "NF}' students.csv
	[ "$status" -eq 0 ]
	[ -z "$output" ]
}

@test "students: self-closing and empty elements become NULL" {
	convert_fixture students-basic
	# Row 1: <lecturer1/>, <lecturer2/>, <exam_mark/>
	[ "$(sed -n 2p students.csv | cut -d, -f11,12,16)" = "NULL,NULL,NULL" ]
	# Row 2: <coursework1></coursework1> and <coursework3/>
	[ "$(sed -n 3p students.csv | cut -d, -f17,19)" = "NULL,NULL" ]
}

@test "students: two-line address is joined with a space" {
	convert_fixture students-basic
	[ "$(sed -n 2p students.csv | cut -d, -f6)" = "12 Engine Street Flat 3 Marylebone London NW1 1AA" ]
}

@test "students: commas inside values are removed so columns stay aligned" {
	convert_fixture students-basic
	[ "$(sed -n 2p students.csv | cut -d, -f13)" = "Faculty of Engineering Physical Sciences" ]
}

@test "students: quotes and entities pass through unchanged" {
	convert_fixture students-basic
	[ "$(sed -n 3p students.csv | cut -d, -f9)" = 'Algorithms "and" Data Structures' ]
	[ "$(sed -n 4p students.csv | cut -d, -f9)" = 'Distributed Systems &amp; Networks' ]
}

@test "students: CRLF input gives LF-only output" {
	sed 's/$/\r/' "$FIXTURES/students-basic/students.xml" > students.xml
	run bash "$REPO_ROOT/xml-to-csv.sh" students.xml
	[ "$status" -eq 0 ]
	run grep -c $'\r' students.csv
	[ "$output" = "0" ]
	assert_same_file "$FIXTURES/students-basic/expected.csv" students.csv
}

# --- empty, malformed and missing input ----------------------------------
# The script does no XML validation and has no error handling: it always
# exits 0. These tests record that so it is visible rather than a surprise.

@test "empty input: faculty mode writes an empty faculty.csv" {
	: > faculty.xml
	run bash "$REPO_ROOT/xml-to-csv.sh" faculty.xml
	[ "$status" -eq 0 ]
	[ -f faculty.csv ]
	[ ! -s faculty.csv ]
}

@test "empty input: students mode writes an empty students.csv" {
	: > students.xml
	run bash "$REPO_ROOT/xml-to-csv.sh" students.xml
	[ "$status" -eq 0 ]
	[ -f students.csv ]
	[ ! -s students.csv ]
}

@test "malformed XML limitation: not rejected, exits 0 with a wrong header" {
	convert_fixture malformed
	[ "$status" -eq 0 ]
	[ "$(head -n 1 faculty.csv)" != "faculty,building,room,capacity" ]
}

@test "missing input file limitation: errors on stderr but exits 0 with empty output" {
	run bash "$REPO_ROOT/xml-to-csv.sh" does-not-exist.xml
	[ "$status" -eq 0 ]
	[[ "$output" == *"No such file or directory"* ]]
	[ ! -s faculty.csv ]
}
