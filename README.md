# xml-to-csv-converter

Bash scripts that convert a university's student and faculty records from XML to CSV, and pull unique values out of the results. They use only standard Unix tools: `grep -P`, `sed`, `awk`, `tr`, `sort` and `uniq`. `xml-to-csv.sh` needs GNU grep (for `-P`) and a UTF-8 locale, e.g. `export LC_ALL=C.UTF-8`.

> Coursework for the University of Southampton Data Management module (COMP1314, 2024). All the data is synthetic: the names, IDs, addresses and the university itself are generated.

## Prerequisites

- Bash with GNU `grep` (for `-P`), `sed`, `awk`, `tr`, `sort` and `uniq`. On Windows, use Git Bash (bundled with [Git for Windows](https://git-scm.com/download/win)); on Linux these are standard. macOS's BSD `grep` has no `-P`, so install GNU grep first.
- A UTF-8 locale: `export LC_ALL=C.UTF-8` (already the default in Git Bash).

No API keys or other setup are needed.

## Run

From this folder in Git Bash:

```bash
export LC_ALL=C.UTF-8
./xml-to-csv.sh students.xml          # writes students.csv
./xml-to-csv.sh faculty.xml           # writes faculty.csv
./unique-names.sh students.csv students.txt
```

The output file names are fixed: an input named exactly `students.xml` writes `students.csv`, and any other input is treated as faculty data and writes `faculty.csv`, both in the current folder. Running the commands above overwrites the committed CSVs with freshly generated copies.

## Testing

The test suite uses [bats-core](https://github.com/bats-core/bats-core). From this folder in Git Bash (or any Bash):

```bash
./tests/run.sh
```

If `bats` is not on your PATH, `run.sh` clones bats-core v1.11.1 into `tests/.bats-core/` (git-ignored, local to this repo) on first run, so the only prerequisites are the ones above plus `git`. Extra arguments go to bats, e.g. `./tests/run.sh --filter students`. Every test runs in its own temp directory, so the committed CSVs are never overwritten. GitHub Actions runs the same command on Ubuntu and Windows for every push to `main` and every pull request.

What the suites prove:

| File | What it checks |
|---|---|
| `tests/setup_check.bats` | The setup check. GNU `grep -P` works, the real scripts turn the bundled sample `tests/fixtures/students-basic/students.xml` into exactly `expected.csv`, and the full `students.xml` / `faculty.xml` regenerate the committed `students.csv`, `faculty.csv` and `students.txt`. If this passes, your toolchain is hooked up correctly. |
| `tests/converter.bats` | `xml-to-csv.sh` on small fixtures: flat faculty records, 19-field student records with a two-line address, repeated records, self-closing and empty elements becoming `NULL`, commas, quotes, `&amp;` entities and CRLF input, attributes, empty input, malformed XML and a missing input file. |
| `tests/unique_names.bats` | `unique-names.sh` sorts, de-duplicates and skips the header. |

Tests whose names contain "limitation" record what the scripts currently do with input they were not designed for: commas inside faculty values are not escaped, an empty faculty field shifts the later columns, an attribute in the first record corrupts the header, and malformed XML or a missing file still exits 0. They pass today. If you fix one of these, update its test.

Fixtures live in `tests/fixtures/<case>/`. Each has an input XML and, where useful, an `expected.csv`.

## Scripts

### `xml-to-csv.sh` converts XML to CSV

```bash
./xml-to-csv.sh students.xml   # -> students.csv
./xml-to-csv.sh faculty.xml    # -> faculty.csv
```

It builds the CSV header from the XML tag names, strips the tags, removes stray commas and carriage returns, writes `NULL` for empty fields, and joins each record's lines into one row. `students.xml` has 19 fields per record (student, module, staff, location and marks), and `faculty.xml` has 4.

### `unique-names.sh` lists unique values

```bash
./unique-names.sh students.csv names.txt
```

It writes the sorted, de-duplicated values of the first column to the output file, skipping the header.

## Data

| File | Description |
|---|---|
| `students.xml` / `students.csv` | Student–module enrolments with marks |
| `faculty.xml` / `faculty.csv` | Faculty, building and room records |
| `students.txt` | Output of `unique-names.sh students.csv students.txt` (5,435 unique student names) |
