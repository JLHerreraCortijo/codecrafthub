#!/usr/bin/env bash

set -euo pipefail

# This script runs beginner-friendly integration tests against the
# CodeCraftHub Flask API using curl. Start the Flask server first:
#   python app.py
#
# Optional:
#   BASE_URL=http://127.0.0.1:5000 ./test_api.sh

BASE_URL="${BASE_URL:-http://127.0.0.1:5000}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA_FILE="$SCRIPT_DIR/courses.json"
TMP_DIR="$(mktemp -d)"
TEST_FAILED=0

ORIGINAL_DATA_EXISTS=0
if [[ -f "$DATA_FILE" ]]; then
  ORIGINAL_DATA_EXISTS=1
  cp "$DATA_FILE" "$TMP_DIR/courses.json.backup"
fi

cleanup() {
  # Restore the original courses.json so the test run does not leave
  # the project data file changed.
  if [[ "$ORIGINAL_DATA_EXISTS" -eq 1 ]]; then
    cp "$TMP_DIR/courses.json.backup" "$DATA_FILE"
  else
    rm -f "$DATA_FILE"
  fi

  rm -rf "$TMP_DIR"
}

trap cleanup EXIT

cat >"$DATA_FILE" <<'EOF'
[]
EOF

cat >"$TMP_DIR/create-course.json" <<'EOF'
{
  "name": "Flask REST API Basics",
  "description": "Learn CRUD operations with Flask",
  "target_date": "2026-06-30",
  "status": "Not Started"
}
EOF

cat >"$TMP_DIR/update-course.json" <<'EOF'
{
  "name": "Flask REST API Advanced",
  "description": "Update the course with more advanced Flask topics",
  "target_date": "2026-07-15",
  "status": "In Progress"
}
EOF

print_section() {
  echo
  echo "============================================================"
  echo "$1"
  echo "============================================================"
}

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1"
    exit 1
  fi
}

check_server() {
  if ! curl -sS "$BASE_URL/api/courses" >/dev/null 2>&1; then
    echo "Could not connect to $BASE_URL"
    echo "Start the Flask server first with: python app.py"
    exit 1
  fi
}

run_test() {
  local name="$1"
  local method="$2"
  local path="$3"
  local expected_status="$4"
  local payload_file="${5:-}"
  local response_file="$TMP_DIR/response.json"
  local actual_status
  shift 5
  local expected_texts=("$@")

  echo
  echo "Test: $name"
  echo "Request: $method $BASE_URL$path"

  if [[ -n "$payload_file" ]]; then
    actual_status="$(
      curl -sS -o "$response_file" -w "%{http_code}" \
        -X "$method" "$BASE_URL$path" \
        -H "Content-Type: application/json" \
        --data @"$payload_file"
    )"
  else
    actual_status="$(
      curl -sS -o "$response_file" -w "%{http_code}" \
        -X "$method" "$BASE_URL$path"
    )"
  fi

  echo "Expected status: $expected_status"
  echo "Actual status:   $actual_status"
  echo "Response body:"
  cat "$response_file"
  echo

  if [[ "$actual_status" != "$expected_status" ]]; then
    echo "Result: FAIL (unexpected status code)"
    TEST_FAILED=1
    return
  fi

  for expected_text in "${expected_texts[@]}"; do
    if [[ -n "$expected_text" ]] && ! grep -Fq "$expected_text" "$response_file"; then
      echo "Result: FAIL (expected text not found: $expected_text)"
      TEST_FAILED=1
      return
    fi
  done

  echo "Result: PASS"
}

require_command curl
check_server

print_section "CodeCraftHub API Test Script"
echo "Base URL: $BASE_URL"
echo "The script reset courses.json for the test run and will restore it afterward."

print_section "Successful CRUD Tests"
run_test \
  "Create a new course" \
  "POST" \
  "/api/courses" \
  "201" \
  "$TMP_DIR/create-course.json" \
  '"Flask REST API Basics"'

run_test \
  "Get all courses" \
  "GET" \
  "/api/courses" \
  "200" \
  "" \
  '"Flask REST API Basics"'

run_test \
  "Get course statistics after creating one course" \
  "GET" \
  "/api/courses/stats" \
  "200" \
  "" \
  '"total_courses"' \
  '"Not Started"'

run_test \
  "Get course with ID 1" \
  "GET" \
  "/api/courses/1" \
  "200" \
  "" \
  '"Not Started"'

run_test \
  "Update course with ID 1" \
  "PUT" \
  "/api/courses/1" \
  "200" \
  "$TMP_DIR/update-course.json" \
  '"In Progress"'

run_test \
  "Get course statistics after updating one course" \
  "GET" \
  "/api/courses/stats" \
  "200" \
  "" \
  '"courses_by_status"' \
  '"In Progress"'

run_test \
  "Delete course with ID 1" \
  "DELETE" \
  "/api/courses/1" \
  "200" \
  "" \
  'Course deleted successfully.'

print_section "Error Handling Tests"

cat >"$TMP_DIR/missing-fields.json" <<'EOF'
{
  "name": "Only Name"
}
EOF

run_test \
  "Create course with missing required fields" \
  "POST" \
  "/api/courses" \
  "400" \
  "$TMP_DIR/missing-fields.json" \
  'Missing required fields'

cat >"$TMP_DIR/invalid-status.json" <<'EOF'
{
  "name": "Bad Status",
  "description": "Testing invalid status",
  "target_date": "2026-06-30",
  "status": "Paused"
}
EOF

run_test \
  "Create course with invalid status" \
  "POST" \
  "/api/courses" \
  "400" \
  "$TMP_DIR/invalid-status.json" \
  'Invalid status'

cat >"$TMP_DIR/invalid-date.json" <<'EOF'
{
  "name": "Bad Date",
  "description": "Testing invalid date",
  "target_date": "06-30-2026",
  "status": "Not Started"
}
EOF

run_test \
  "Create course with invalid date format" \
  "POST" \
  "/api/courses" \
  "400" \
  "$TMP_DIR/invalid-date.json" \
  'Invalid target_date'

cat >"$TMP_DIR/non-object-body.json" <<'EOF'
[]
EOF

run_test \
  "Create course with a JSON array instead of an object" \
  "POST" \
  "/api/courses" \
  "400" \
  "$TMP_DIR/non-object-body.json" \
  'Request body must be a valid JSON object.'

run_test \
  "Get a course that does not exist" \
  "GET" \
  "/api/courses/999" \
  "404" \
  "" \
  'Course not found.'

run_test \
  "Update a course that does not exist" \
  "PUT" \
  "/api/courses/999" \
  "404" \
  "$TMP_DIR/update-course.json" \
  'Course not found.'

run_test \
  "Delete a course that does not exist" \
  "DELETE" \
  "/api/courses/999" \
  "404" \
  "" \
  'Course not found.'

print_section "Test Summary"

if [[ "$TEST_FAILED" -eq 1 ]]; then
  echo "One or more tests failed."
  exit 1
fi

echo "All tests passed."
