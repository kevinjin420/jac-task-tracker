node user {
    has name: str;
}

node course {
    has code: str;
    has title: str;
    has description: str = "";
    has usage_count: int = 0;
    has keywords: list = [];
}

node task {
    has assignment: str;  # Task/assignment name
    has due_date: str;  # ISO format date string
    has description: str = "";  # Optional description
    has status: str = "todo";  # Status like "todo", "in progress", "done"
    has created_at: str = "";  # Timestamp for tracking patterns over time
}

# Edges define relationships in the graph
edge assigned_to {
    # Links user to tasks
}

edge belongs_to {
    # Links task to course
}

# Object for passing course information to AI classification
obj CourseInfo {
    has code: str;
    has title: str;
    has description: str;
    has usage_count: int;
    has keywords: list;
}
