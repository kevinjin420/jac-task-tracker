# Task Tracker Backend

This directory contains the Jac backend for the task tracker application.

## File Structure

```
backend/
├── types.jac      - Data type definitions (nodes, objects)
├── walkers.jac    - Walker definitions (API logic)
├── main.jac       - Entry point (includes all modules)
└── README.md      - This file
```

## Data Model

### Nodes

**column_schema** - Defines table columns
- `name: str` - Column name (e.g., "assignment", "status")
- `type: str` - Data type: "text", "select", "multiselect", "date"
- `options: list` - Options for select/multiselect columns
- `required: bool` - Whether field is required
- `order: int` - Display order in table

**task** - Stores task data
- `fields: dict[str, any]` - Dynamic fields based on column schema
- `created_at: str` - Creation timestamp

### Graph Structure

```
root
├──> column_schema (assignment)
├──> column_schema (status)
├──> column_schema (courses)
├──> column_schema (due_date)
├──> task (fields: {assignment: "...", status: "..."})
├──> task (fields: {assignment: "...", status: "..."})
└──> task (...)
```

## API Endpoints

All walkers are automatically exposed as HTTP POST endpoints:

### Column Management

- `POST /walker/init_default_columns` - Initialize default columns
- `POST /walker/get_columns` - Get all column definitions
- `POST /walker/add_column` - Add a new column
  - Body: `{name, type, options, required}`
- `POST /walker/update_column` - Update column properties
  - Body: `{name, new_type, new_options}`
- `POST /walker/delete_column` - Delete a column
  - Body: `{name}`

### Task Management

- `POST /walker/get_tasks` - Get all tasks
- `POST /walker/add_task` - Create a new task
  - Body: `{fields: {assignment: "...", status: "..."}}`
- `POST /walker/update_task` - Update task fields
  - Body: `{task_id, id_field, fields}`
- `POST /walker/delete_task` - Delete a task
  - Body: `{task_id, id_field}`

## Running the Server

```bash
jac serve main.jac
```

The server will start on port 8000 by default.

## Example Usage

### Initialize default columns
```bash
curl -X POST http://localhost:8000/walker/init_default_columns
```

### Get columns
```bash
curl -X POST http://localhost:8000/walker/get_columns
```

### Add a task
```bash
curl -X POST http://localhost:8000/walker/add_task \
  -H "Content-Type: application/json" \
  -d '{
    "fields": {
      "assignment": "Complete homework",
      "status": "todo",
      "due_date": "2025-10-25",
      "courses": ["CS161", "MATH"]
    }
  }'
```

### Get all tasks
```bash
curl -X POST http://localhost:8000/walker/get_tasks
```
