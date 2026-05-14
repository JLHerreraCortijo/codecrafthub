# CodeCraftHub

CodeCraftHub is a beginner-friendly Flask project that teaches the basics of building a REST API in Python. The API lets developers keep track of courses they want to learn, update their progress, and remove courses they no longer need.

This project is intentionally simple:

- It uses `Flask` instead of a full framework stack.
- It stores data in a plain `courses.json` file.
- It does not use a database.
- It does not include authentication or user accounts.

If you are learning REST APIs for the first time, this is a good project because you can focus on HTTP methods, JSON requests, JSON responses, and CRUD operations without extra complexity.

## Features

- Create a new learning course
- View all saved courses
- View one course by ID
- Update an existing course
- Delete a course
- Validate required fields
- Validate course status values
- Validate date format as `YYYY-MM-DD`
- Auto-generate `id` and `created_at`
- Auto-create `courses.json` if it does not exist
- Return clear JSON error messages

## Tech Stack

- Python 3
- Flask
- JSON file storage

## Project Structure

```text
codecrafthub/
├── app.py
├── requirements.txt
├── README.md
├── test_api.sh
└── courses.json
```

### What each file does

- `app.py`: Main Flask application with all API routes and validation logic
- `requirements.txt`: Python dependencies for the project
- `README.md`: Project documentation and beginner guide
- `test_api.sh`: Shell script that runs API tests with `curl`
- `courses.json`: Stores course data in JSON format and is created automatically when needed

## How the Project Works

The API manages a list of courses. Each course contains:

- `id`: Auto-generated integer starting from `1`
- `name`: Course name
- `description`: Short description of the course
- `target_date`: Planned completion date in `YYYY-MM-DD` format
- `status`: One of `Not Started`, `In Progress`, or `Completed`
- `created_at`: Auto-generated UTC timestamp

Data is stored in a local file called `courses.json`. Every time you create, update, or delete a course, the API reads the file, changes the data in memory, and writes the updated list back to the file.

## Installation

Follow these steps from the project folder.

### 1. Check that Python is installed

```bash
python3 --version
```

If you see a version number, Python is installed.

### 2. Create a virtual environment

```bash
python3 -m venv .venv
```

A virtual environment keeps your project dependencies separate from the rest of your system.

### 3. Activate the virtual environment

macOS and Linux:

```bash
source .venv/bin/activate
```

Windows PowerShell:

```powershell
.venv\Scripts\Activate.ps1
```

### 4. Install dependencies

```bash
pip install -r requirements.txt
```

### 5. Confirm Flask is installed

```bash
python -c "import flask; print(flask.__version__)"
```

## How to Run the Application

Start the Flask server with:

```bash
python app.py
```

You should see output similar to this:

```text
 * Serving Flask app 'app'
 * Debug mode: on
 * Running on http://127.0.0.1:5000
```

Once the server is running, the API will be available at:

```text
http://127.0.0.1:5000
```

The first time the app runs, it will automatically create `courses.json` if the file does not already exist.

## API Endpoints

All endpoints use the `/api/courses` base path.

### 1. Create a Course

**Endpoint**

```text
POST /api/courses
```

**Example Request**

```bash
curl -i -X POST http://127.0.0.1:5000/api/courses \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Flask REST API Basics",
    "description": "Learn CRUD operations with Flask",
    "target_date": "2026-06-30",
    "status": "Not Started"
  }'
```

**Successful Response**

Status: `201 Created`

```json
{
  "created_at": "2026-05-14T10:30:00Z",
  "description": "Learn CRUD operations with Flask",
  "id": 1,
  "name": "Flask REST API Basics",
  "status": "Not Started",
  "target_date": "2026-06-30"
}
```

### 2. Get All Courses

**Endpoint**

```text
GET /api/courses
```

**Example Request**

```bash
curl -i http://127.0.0.1:5000/api/courses
```

**Successful Response**

Status: `200 OK`

```json
[
  {
    "created_at": "2026-05-14T10:30:00Z",
    "description": "Learn CRUD operations with Flask",
    "id": 1,
    "name": "Flask REST API Basics",
    "status": "Not Started",
    "target_date": "2026-06-30"
  }
]
```

### 3. Get One Course by ID

**Endpoint**

```text
GET /api/courses/<id>
```

**Example Request**

```bash
curl -i http://127.0.0.1:5000/api/courses/1
```

**Successful Response**

Status: `200 OK`

```json
{
  "created_at": "2026-05-14T10:30:00Z",
  "description": "Learn CRUD operations with Flask",
  "id": 1,
  "name": "Flask REST API Basics",
  "status": "Not Started",
  "target_date": "2026-06-30"
}
```

### 4. Update a Course

**Endpoint**

```text
PUT /api/courses/<id>
```

**Example Request**

```bash
curl -i -X PUT http://127.0.0.1:5000/api/courses/1 \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Flask REST API Advanced",
    "description": "Update the course with more advanced Flask topics",
    "target_date": "2026-07-15",
    "status": "In Progress"
  }'
```

**Successful Response**

Status: `200 OK`

```json
{
  "created_at": "2026-05-14T10:30:00Z",
  "description": "Update the course with more advanced Flask topics",
  "id": 1,
  "name": "Flask REST API Advanced",
  "status": "In Progress",
  "target_date": "2026-07-15"
}
```

### 5. Delete a Course

**Endpoint**

```text
DELETE /api/courses/<id>
```

**Example Request**

```bash
curl -i -X DELETE http://127.0.0.1:5000/api/courses/1
```

**Successful Response**

Status: `200 OK`

```json
{
  "message": "Course deleted successfully."
}
```

## Valid Request Rules

When creating or updating a course:

- `name` is required
- `description` is required
- `target_date` is required
- `target_date` must use the format `YYYY-MM-DD`
- `status` is required
- `status` must be one of:
  - `Not Started`
  - `In Progress`
  - `Completed`

The API automatically generates:

- `id`
- `created_at`

## Testing the API

Use these steps to test the full CRUD flow.

### Step 1. Start the server

```bash
python app.py
```

### Step 2. Create a course

```bash
curl -i -X POST http://127.0.0.1:5000/api/courses \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Python APIs",
    "description": "Learn Flask routing and JSON responses",
    "target_date": "2026-08-01",
    "status": "Not Started"
  }'
```

### Step 3. Get all courses

```bash
curl -i http://127.0.0.1:5000/api/courses
```

### Step 4. Get one course

```bash
curl -i http://127.0.0.1:5000/api/courses/1
```

### Step 5. Update the course

```bash
curl -i -X PUT http://127.0.0.1:5000/api/courses/1 \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Python APIs Updated",
    "description": "Practice CRUD endpoints and validation",
    "target_date": "2026-08-15",
    "status": "In Progress"
  }'
```

### Step 6. Delete the course

```bash
curl -i -X DELETE http://127.0.0.1:5000/api/courses/1
```

### Run the included shell test script

The project also includes a reusable test script called `test_api.sh`.

Make it executable once:

```bash
chmod +x test_api.sh
```

Then, with the Flask server running, execute:

```bash
./test_api.sh
```

The script:

- Runs the main CRUD tests
- Runs common error-case tests
- Prints each request, response, and result
- Temporarily resets `courses.json` for a clean test run
- Restores the original `courses.json` after the tests finish

## Error Testing Examples

These examples help you learn how the API handles invalid requests.

### Missing required fields

```bash
curl -i -X POST http://127.0.0.1:5000/api/courses \
  -H "Content-Type: application/json" \
  -d '{"name":"Only Name"}'
```

Expected response:

Status: `400 Bad Request`

```json
{
  "error": "Missing required fields: description, target_date, status"
}
```

### Invalid status value

```bash
curl -i -X POST http://127.0.0.1:5000/api/courses \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Bad Status",
    "description": "Testing invalid status",
    "target_date": "2026-06-30",
    "status": "Paused"
  }'
```

Expected response:

Status: `400 Bad Request`

```json
{
  "error": "Invalid status. Allowed values: \"Not Started\", \"In Progress\", \"Completed\"."
}
```

### Invalid date format

```bash
curl -i -X POST http://127.0.0.1:5000/api/courses \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Bad Date",
    "description": "Testing invalid date",
    "target_date": "06-30-2026",
    "status": "Not Started"
  }'
```

Expected response:

Status: `400 Bad Request`

```json
{
  "error": "Invalid target_date. Use the format \"YYYY-MM-DD\"."
}
```

### Course not found

```bash
curl -i http://127.0.0.1:5000/api/courses/999
```

Expected response:

Status: `404 Not Found`

```json
{
  "error": "Course not found."
}
```

## Understanding the JSON Storage

Unlike larger projects, this app does not use MySQL, PostgreSQL, or MongoDB. Instead, it stores data in a single file called `courses.json`.

Example:

```json
[
  {
    "id": 1,
    "name": "Flask REST API Basics",
    "description": "Learn CRUD operations with Flask",
    "target_date": "2026-06-30",
    "status": "Not Started",
    "created_at": "2026-05-14T10:30:00Z"
  }
]
```

This approach is useful for learning because:

- It is easy to inspect the data by opening the file
- There is no database setup
- You can focus on REST concepts first

This approach is not ideal for large production applications because file-based storage is limited and not designed for many users at the same time.

## Troubleshooting

### `ModuleNotFoundError: No module named 'flask'`

Flask is not installed in your current Python environment.

Fix:

```bash
pip install -r requirements.txt
```

If you are using a virtual environment, make sure it is activated first.

### `python: command not found`

Your system may use `python3` instead of `python`.

Try:

```bash
python3 app.py
```

### `Address already in use`

Another program is already using port `5000`.

Fix:

- Stop the other program using that port
- Or run Flask on a different port using:

```bash
flask --app app run --port 5001
```

### `courses.json contains invalid JSON data`

The JSON file may have been edited manually and broken.

Fix:

- Open `courses.json`
- Check for missing commas, missing quotes, or broken brackets
- If needed, replace the file contents with:

```json
[]
```

### My API returns `400 Bad Request`

Check the request body carefully:

- Are all required fields included?
- Is `target_date` in `YYYY-MM-DD` format?
- Is `status` exactly one of `Not Started`, `In Progress`, or `Completed`?
- Are you sending `Content-Type: application/json` in your request?

## Beginner REST API Concepts in This Project

This project demonstrates the core ideas of REST:

- `POST` creates a new resource
- `GET` reads one or more resources
- `PUT` updates an existing resource
- `DELETE` removes a resource

It also demonstrates common API practices:

- Returning JSON responses
- Using HTTP status codes
- Validating incoming data
- Handling errors clearly

## Next Ideas for Improvement

After you understand this version, you could extend the project with:

- Search or filter courses by status
- Sort courses by target date
- Add `PATCH` support for partial updates
- Add unit tests with `pytest`
- Move from JSON file storage to a real database
- Build a simple frontend page for the API

## License

This project is for learning and practice.
