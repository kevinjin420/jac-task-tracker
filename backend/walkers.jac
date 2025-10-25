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
glob llm = Model(model_name="gemini-2.0-flash", api_key=GEMINI_API_KEY);

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

walker suggest_category {
    obj __specs__ {
        static has auth: bool = False;
    }

    has task_name: str;

    can execute with `root entry {
        category_column = null;
        for col in [here --> (`?column_schema)] {
            if col.name == "category" {
                category_column = col;
                break;
            }
        }

        if category_column and category_column.options {
            categories = category_column.options;
            prompt = f"Classify the task '{self.task_name}' into one of the following categories: {categories}. Only return the single best category name from the list.";
            response = llm.generate(prompt=prompt);
            suggested_category = response.strip();

            if suggested_category in categories {
               report {"success": True, "category": suggested_category};
            } else {
               report {"success": False, "message": "Could not determine a category."};
            }
        } else {
            report {"success": False, "message": "Category column or options not found."};
        }
    }
}

# ============ TASK MANAGEMENT ============

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

walker add_task {
    """Create a new task with dynamic fields"""
    obj __specs__ {
        static has auth: bool = False;
    }

    has fields: dict = {};

    can create with `root entry {
        current_time = "2025-10-20T00:00:00";

        here ++> task(
            fields=self.fields,
            created_at=current_time
        );

        report {
            "success": True,
            "message": "Task created",
            "task": {"fields": self.fields, "created_at": current_time}
        };
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