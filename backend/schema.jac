enum ColumnType {
    TEXT,
    SELECT,
    MULTISELECT,
    DATE
}

node category_store {
    has options: list = [];
}

node task {
    has name: str = "";
    has category: list[str] = [];
    has status: str = "not started";
    has due_date: str = "";
    has created_at: str = "";
}