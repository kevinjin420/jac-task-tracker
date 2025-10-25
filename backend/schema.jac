"""
types.jac - Data type definitions for the task tracker

Defines:
- column_schema: Stores table column definitions (name, type, options)
- task: Stores task data with dynamic fields based on column schema
"""

enum ColumnType {
    TEXT,
    SELECT,
    MULTISELECT,
    DATE
}

enum Status {
    NOT_STARTED = "not started",
    IN_PROGRESS = "in progress",
    DONE = "done"
}

node column_schema {
    has name: str;
    has type: ColumnType;
    has options: list = [];
    has order: int = 0;
}

node task {
    has fields: dict[str, any] = {};
    has created_at: str = "";
}
