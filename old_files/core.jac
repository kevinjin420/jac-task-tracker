node user {
    has name: str;
}

node column_schema {
    has name: str;              # Column name (e.g., "assignment", "status")
    has type: str;              # Data type: "text", "select", "multiselect", "date"
    has options: list = [];     # For select/multiselect types
    has required: bool = False;
    has order: int = 0;         # Display order
}

node task {
    has fields: dict[str, any] = {};  # Dynamic fields based on column schema
    has created_at: str = "";
}

edge assigned_to;
