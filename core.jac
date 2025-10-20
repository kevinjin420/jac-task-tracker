node user {
    has name: str;
}

node course {
    has code: str;  # Course number, project team, company, or personal tag
    has title: str;  # Course title
    has usage_count: int = 0;  # Track frequency for learning
    has keywords: list = [];  # Keywords associated with this course
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
