"""
walkers.jac - Walker definitions for managing columns and tasks

Column Management Walkers:
- init_default_columns: Initialize default table columns
- get_columns: Retrieve all column definitions
- add_column: Add a new column to the schema
- update_column: Update column properties
- delete_column: Remove a column

Task Management Walkers:
- get_tasks: Retrieve all tasks
- add_task: Create a new task
- update_task: Update task fields
- delete_task: Remove a task
"""

import from schema { column_schema, ColumnType, Status, task }
import os;
import from byllm.llm {Model}

glob GEMINI_API_KEY = os.getenv("GEMINI_API_KEY");
glob llm = Model(model_name="gemini/gemini-2.0-flash-exp", api_key=GEMINI_API_KEY);

# ============ LLM HELPER FUNCTIONS ============

"""Categorize a task based on available categories and their contexts"""
def categorize_task(task_name: str, categories: list[dict]) -> str by llm();
sem categorize_task = """
Analyze the task name and determine which category it best fits into.
Each category has a name and context. Return ONLY the category name, nothing else.
Choose the most appropriate category based on the context provided.
""";

# ============ COLUMN SCHEMA MANAGEMENT ============

walker init_default_columns {
    """Initialize default table columns"""
    obj __specs__ {
        static has auth: bool = False;
    }

    can create with `root entry {
        existing = [here --> (`?column_schema)];
        if len(existing) == 0 {
            here ++> column_schema(name="category", type=ColumnType.MULTISELECT, options=[], order=0);
            here ++> column_schema(name="name", type=ColumnType.TEXT, order=1);
            here ++> column_schema(name="status", type=ColumnType.SELECT, options=["not started", "in progress", "done"], order=2);
            here ++> column_schema(name="due_date", type=ColumnType.DATE, order=3);
            report {"success": True, "message": "Default columns created"};
        } else {
            report {"success": False, "message": "Default columns already exist"};
        }
    }
}

walker get_columns {
    """Get all column definitions sorted by order"""
    obj __specs__ {
        static has auth: bool = False;
    }

    can execute with `root entry {
        columns = [];
        for col in [here --> (`?column_schema)] {
            columns.append({
                "name": col.name,
                "type": col.type.name,
                "options": col.options,
                "order": col.order
            });
        }

        columns.sort(key=lambda x: dict : x["order"]);
        report {"success": True, "columns": columns};
    }
}

walker add_column {
    """Add a new column to the schema"""
    obj __specs__ {
        static has auth: bool = False;
    }

    has name: str;
    has type: str = "text";
    has options: list = [];

    can create with `root entry {
        existing = [here --> (`?column_schema)];
        for col in existing {
            if col.name == self.name {
                report {"success": False, "message": f"Column '{self.name}' already exists"};
                disengage;
            }
        }

        order = len(existing);

        here ++> column_schema(
            name=self.name,
            type=ColumnType[self.type.upper()],
            options=self.options,
            order=order
        );

        report {
            "success": True,
            "message": f"Column '{self.name}' created",
            "column": {"name": self.name, "type": self.type, "options": self.options}
        };
    }
}

walker update_column {
    """Update column properties"""
    obj __specs__ {
        static has auth: bool = False;
    }

    has name: str;
    has new_type: str = "";
    has new_options: list = [];

    can update with column_schema entry {
        if here.name == self.name {
            if self.new_type {
                here.type = ColumnType[self.new_type.upper()];
            }
            if len(self.new_options) > 0 {
                here.options = self.new_options;
            }
        }
    }

    can execute with `root entry {
        for col in [here --> (`?column_schema)] {
            visit col;
        }
        report {"success": True, "message": f"Column '{self.name}' updated"};
    }
}

walker delete_column {
    """Delete a column from the schema"""
    obj __specs__ {
        static has auth: bool = False;
    }

    has name: str;

    can remove with column_schema entry {
        if here.name == self.name {
            del here;
        }
    }

    can execute with `root entry {
        for col in [here --> (`?column_schema)] {
            visit col;
        }
        report {"success": True, "message": f"Column '{self.name}' deleted"};
    }
}

walker add_task_with_ai_category {
    """Create a new task and use AI to suggest the category."""
    obj __specs__ {
        static has auth: bool = False;
    }

    has task_name: str;

    can create with `root entry {
        # 1. Find category column and options
        category_column = None;
        for col in [here --> (`?column_schema)] {
            if col.name == "category" {
                category_column = col;
                break;
            }
        }

        suggested_category = "General"; # Default category

        # 2. If categories exist, use LLM to suggest one
        if category_column and category_column.options {
            categories = category_column.options;
            category_info = [];
            for cat in categories {
                if (isinstance(cat, dict)) {
                    category_info.append(cat);
                } else {
                    category_info.append({"name": cat, "context": ""});
                }
            }

            if len(category_info) > 0 {
                suggested_category = categorize_task(self.task_name, category_info);
            }
        }

        # 3. Find default status
        status_column = None;
        for col in [here --> (`?column_schema)] {
            if col.name == "status" {
                status_column = col;
                break;
            }
        }
        not_started = "not started";
        if status_column and status_column.options {
            for opt in status_column.options {
                if opt.lower() == "not started" {
                    not_started = opt;
                    break;
                }
            }
        }

        # 4. Create the new task
        current_time = "2025-10-20T00:00:00"; # Placeholder
        today = "2025-10-20"; # Placeholder

        new_task_nodes = here ++> task(
            fields={
                "name": self.task_name,
                "category": [suggested_category],
                "status": not_started,
                "due_date": today
            },
            created_at=current_time
        );

        if len(new_task_nodes) > 0 {
            actual_task_node = new_task_nodes[0];
            report {
                "success": True,
                "message": "Task created with AI category",
                "task": {
                    "fields": actual_task_node.fields,
                    "created_at": actual_task_node.created_at
                }
            };
        } else {
            report {"success": False, "message": "Task node creation failed." };
        }
    }
}

walker update_task {
    """Update task fields by ID"""
    obj __specs__ {
        static has auth: bool = False;
    }

    has task_id: str;
    has id_field: str = "assignment";
    has fields: dict = {};

    can update with task entry {
        if self.id_field in here.fields and here.fields[self.id_field] == self.task_id {
            for (key, value) in self.fields.items() {
                here.fields[key] = value;
            }
        }
    }

    can execute with `root entry {
        for t in [here --> (`?task)] {
            visit t;
        }
        report {"success": True, "message": "Task updated"};
    }
}

walker delete_task {
    """Delete a task by ID"""
    obj __specs__ {
        static has auth: bool = False;
    }

    has task_id: str;
    has id_field: str = "assignment";

    can remove with task entry {
        if self.id_field in here.fields and here.fields[self.id_field] == self.task_id {
            del here;
        }
    }

    can execute with `root entry {
        for t in [here --> (`?task)] {
            visit t;
        }
        report {"success": True, "message": "Task deleted"};
    }
}

walker get_tasks {
    """Get all tasks"""
    obj __specs__ {
        static has auth: bool = False;
    }

    can execute with `root entry {
        tasks = [];
        for t in [here --> (`?task)] {
            tasks.append({
                "fields": t.fields,
                "created_at": t.created_at
            });
        }

        report {"success": True, "tasks": tasks};
    }
}