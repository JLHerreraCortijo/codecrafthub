"""Simple Flask REST API for managing learning courses in CodeCraftHub."""

from datetime import datetime, timezone
from pathlib import Path
import json
import re

from flask import Flask, jsonify, request

app = Flask(__name__)

# Allow routes to work with or without a trailing slash.
app.url_map.strict_slashes = False

# Store the JSON file in the same folder as this app.py file.
DATA_FILE = Path(__file__).resolve().parent / "courses.json"
REQUIRED_FIELDS = ("name", "description", "target_date", "status")
VALID_STATUSES = {"Not Started", "In Progress", "Completed"}
DATE_PATTERN = re.compile(r"^\d{4}-\d{2}-\d{2}$")


class StorageError(Exception):
    """Raised when the application cannot read from or write to the JSON file."""


def error_response(message, status_code):
    """Return a consistent JSON error response."""
    return jsonify({"error": message}), status_code


def ensure_data_file():
    """Create courses.json with an empty list if it does not exist yet."""
    if DATA_FILE.exists():
        return

    try:
        DATA_FILE.write_text("[]\n", encoding="utf-8")
    except OSError as exc:
        raise StorageError(f"Could not create {DATA_FILE.name}: {exc}") from exc


def load_courses():
    """Load all courses from the JSON file."""
    ensure_data_file()

    try:
        with DATA_FILE.open("r", encoding="utf-8") as file:
            courses = json.load(file)
    except OSError as exc:
        raise StorageError(f"Could not read {DATA_FILE.name}: {exc}") from exc
    except json.JSONDecodeError as exc:
        raise StorageError(f"{DATA_FILE.name} contains invalid JSON data.") from exc

    # The file should always store a list of course objects.
    if not isinstance(courses, list):
        raise StorageError(f"{DATA_FILE.name} must contain a JSON array.")

    return courses


def save_courses(courses):
    """Save the complete list of courses back to the JSON file."""
    try:
        with DATA_FILE.open("w", encoding="utf-8") as file:
            json.dump(courses, file, indent=2)
            file.write("\n")
    except OSError as exc:
        raise StorageError(f"Could not write to {DATA_FILE.name}: {exc}") from exc


def get_next_id(courses):
    """Generate the next course id, starting at 1."""
    if not courses:
        return 1

    return max(course["id"] for course in courses) + 1


def find_course(courses, course_id):
    """Find a single course by id, or return None if it does not exist."""
    return next((course for course in courses if course["id"] == course_id), None)


def is_blank_string(value):
    """Check whether a value is missing or only contains whitespace."""
    return not isinstance(value, str) or not value.strip()


def is_valid_date(date_string):
    """Validate the date format and ensure the date is real."""
    if not isinstance(date_string, str) or not DATE_PATTERN.fullmatch(date_string):
        return False

    try:
        datetime.strptime(date_string, "%Y-%m-%d")
    except ValueError:
        return False

    return True


def validate_course_data(data):
    """Validate request JSON for creating or updating a course."""
    if not isinstance(data, dict):
        return False, "Request body must be a valid JSON object."

    missing_fields = [
        field
        for field in REQUIRED_FIELDS
        if field not in data or is_blank_string(data[field])
    ]
    if missing_fields:
        return False, f"Missing required fields: {', '.join(missing_fields)}"

    normalized_course = {
        "name": data["name"].strip(),
        "description": data["description"].strip(),
        "target_date": data["target_date"].strip(),
        "status": data["status"].strip(),
    }

    if normalized_course["status"] not in VALID_STATUSES:
        return (
            False,
            'Invalid status. Allowed values: "Not Started", "In Progress", "Completed".',
        )

    if not is_valid_date(normalized_course["target_date"]):
        return False, 'Invalid target_date. Use the format "YYYY-MM-DD".'

    return True, normalized_course


@app.errorhandler(StorageError)
def handle_storage_error(error):
    """Return JSON instead of the default HTML 500 error page."""
    return error_response(str(error), 500)


@app.route("/api/courses", methods=["POST"])
def create_course():
    """Create a new course and store it in courses.json."""
    request_data = request.get_json(silent=True)
    is_valid, result = validate_course_data(request_data)
    if not is_valid:
        return error_response(result, 400)

    courses = load_courses()

    new_course = {
        "id": get_next_id(courses),
        "name": result["name"],
        "description": result["description"],
        "target_date": result["target_date"],
        "status": result["status"],
        # Use UTC so timestamps stay consistent across environments.
        "created_at": datetime.now(timezone.utc)
        .replace(microsecond=0)
        .isoformat()
        .replace("+00:00", "Z"),
    }

    courses.append(new_course)
    save_courses(courses)

    return jsonify(new_course), 201


@app.route("/api/courses", methods=["GET"])
def get_courses():
    """Return all stored courses."""
    courses = load_courses()
    return jsonify(courses), 200


@app.route("/api/courses/<int:course_id>", methods=["GET"])
def get_course(course_id):
    """Return a single course by id."""
    courses = load_courses()
    course = find_course(courses, course_id)

    if course is None:
        return error_response("Course not found.", 404)

    return jsonify(course), 200


@app.route("/api/courses/<int:course_id>", methods=["PUT"])
def update_course(course_id):
    """Replace the editable fields of an existing course."""
    request_data = request.get_json(silent=True)
    is_valid, result = validate_course_data(request_data)
    if not is_valid:
        return error_response(result, 400)

    courses = load_courses()
    course = find_course(courses, course_id)

    if course is None:
        return error_response("Course not found.", 404)

    # Keep id and created_at unchanged, and replace only the editable fields.
    course["name"] = result["name"]
    course["description"] = result["description"]
    course["target_date"] = result["target_date"]
    course["status"] = result["status"]

    save_courses(courses)
    return jsonify(course), 200


@app.route("/api/courses/<int:course_id>", methods=["DELETE"])
def delete_course(course_id):
    """Delete a course by id."""
    courses = load_courses()
    course = find_course(courses, course_id)

    if course is None:
        return error_response("Course not found.", 404)

    courses.remove(course)
    save_courses(courses)

    return jsonify({"message": "Course deleted successfully."}), 200


if __name__ == "__main__":
    # Try to create the JSON file when the app starts locally.
    # If that fails, the API will still run and return a clear 500 error later.
    try:
        ensure_data_file()
    except StorageError as error:
        app.logger.error("%s", error)

    app.run(debug=True)
