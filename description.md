# Task Tracker Application: Technical Overview

This document provides a detailed technical overview of the Jac-based Task Tracker application. It covers the development process, data model, API endpoints, and the integration of AI for intelligent task management.

## 1. Development Process

The application was built iteratively by an AI agent (Google's Gemini). The process began with a basic scaffold for a Jac backend and a React/TypeScript frontend. Through a series of user requests, the agent progressively added features, refactored the UI, and fixed bugs.

Key development stages included:
- **Initial Setup:** Scaffolding the project with a Vite-based React frontend and a Jac backend.
- **Core Functionality:** Implementing the basic CRUD (Create, Read, Update, Delete) operations for tasks and table columns.
- **UI/UX Refinement:** Transitioning from a basic layout to a more polished, Bootstrap-based UI. This involved several refactoring cycles based on user feedback, such as moving from buttons to right-click context menus for a cleaner interface.
- **AI Integration:** Introducing AI-powered category suggestions using the `byllm` library, which evolved from a simple suggestion to a core part of the task creation workflow.
- **Debugging:** Systematically diagnosing and fixing bugs by analyzing logs, reading code, and applying targeted fixes. This included resolving Python/Jac import errors, frontend rendering bugs, and data serialization issues.

## 2. Data Model (Graph Schema)

The application's data is structured as a graph, defined in `backend/schema.jac`. The core of the model consists of two node types:

### `column_schema` node
This node defines the structure of the task table itself. Each `column_schema` node represents a column.

- `name: str`: The unique name of the column (e.g., "name", "status", "due_date").
- `type: ColumnType`: An enum (`TEXT`, `SELECT`, `MULTISELECT`, `DATE`) that determines the kind of data the column holds and how it should be rendered on the frontend.
- `options: list`: A list of available choices for `SELECT` and `MULTISELECT` column types.
  - For the "status" column, this is a simple list of strings (e.g., `["not started", "in progress"]`).
  - For the "category" column, this is a list of objects, where each object has a `name` and a `context` field (e.g., `[{ "name": "Work", "context": "Tasks related to my job" }]`). This rich structure provides the necessary information for the AI to make intelligent categorization decisions.
- `order: int`: A number that dictates the left-to-right order of the columns in the table.

### `task` node
This node represents a single task, or a row in the table.

- `fields: dict[str, any]`: A flexible dictionary that holds the actual data for the task. The keys of this dictionary correspond to the `name` of a `column_schema` node (e.g., `{"name": "Write report", "status": "in progress"}`).
- `created_at: str`: A timestamp string indicating when the task was created.

## 3. API Endpoints (Walkers)

The frontend communicates with the Jac backend by calling walkers, which are exposed as API endpoints. All public walkers are defined in `backend/walkers.jac` and are marked with `obj __specs__ { static has auth: bool = False; }`.

Here are the key endpoints:

- **Column Management:**
  - `init_default_columns`: Creates the initial set of columns ("category", "name", "status", "due_date") if none exist.
  - `get_columns`: Retrieves the definition for all existing columns.
  - `add_column`: Adds a new column to the schema.
  - `update_column`: Updates the properties of an existing column (e.g., adding a new option to a `SELECT` or `MULTISELECT` column).
  - `delete_column`: Removes a column from the schema.

- **Task Management:**
  - `get_tasks`: Retrieves all existing tasks.
  - `add_task_with_ai_category`: The primary endpoint for creating a new task. It takes a task name, uses AI to determine the best category, and creates the task with default values.
  - `update_task`: Updates the fields of an existing task.
  - `delete_task`: Deletes a task.

## 4. Understanding Walkers: Graph Traversal and Manipulation

Walkers are a core concept in Jac. They are special agents that can "walk" across the nodes of the graph, reading data and making changes.

- **Traversal:** Walkers use the `-->` operator to traverse from one node to another. For example, in `get_columns`, the code `here --> (
?column_schema)` starts at the graph's root node (`here`) and finds all connected `column_schema` nodes.

- **State & Logic:** Walkers can have their own state (variables) and execute procedural logic. In `get_columns`, the walker initializes an empty `tasks` list and iterates through the found nodes, appending their data to the list before returning it in a `report`.

- **Manipulation:** Walkers use operators like `++>` to create new nodes and `del` to delete them. In `add_task_with_ai_category`, the line `here ++> task(...)` creates a new `task` node and connects it to the root node (`here`).

This graph-based approach is powerful because it allows the data and the logic that acts on it to be modeled together in a very flexible way.

## 5. AI Integration with `byllm`

The application's most advanced feature is its ability to automatically categorize new tasks using the `byllm` library.

This functionality is encapsulated within the `add_task_with_ai_category` walker:

1.  **Data Collection:** When the walker is called with a new task name (e.g., "schedule dentist appointment"), it first traverses the graph to find the `category` column and retrieves its list of options.

2.  **Prompt Engineering:** The walker constructs a detailed, dynamic prompt for the Language Model (LLM). It iterates through the category options and builds a formatted string that presents both the `name` and the `context` for each category. The final prompt looks something like this:

    ```
    Classify the task 'schedule dentist appointment' into one of the following categories based on their context (if provided).

    Categories:
    - Work: Tasks related to my job
    - Personal: Personal errands and appointments
    - Health: Health and wellness related tasks

    Return only the single best category name from this list: ['Work', 'Personal', 'Health'].
    ```

3.  **LLM Invocation:** The walker sends this prompt to the Gemini model via `llm.generate(prompt=prompt)`.

4.  **Response and Validation:** The walker takes the text response from the LLM, strips any extra whitespace, and validates that the returned category name is one of the valid options. If it is, that category is used for the new task. If not, it defaults to a "General" category.

5.  **Task Creation:** Finally, the walker creates the new `task` node, populating its `fields` dictionary with the user-provided name, the AI-inferred category, and sensible defaults for status and due date.

This entire process happens in a single API call, providing a seamless and intelligent experience for the user on the frontend.
