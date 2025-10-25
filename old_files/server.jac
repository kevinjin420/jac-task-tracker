include core;

# ============ COLUMN SCHEMA MANAGEMENT ============

walker add_column {
    has name: str;
    has type: str = "text";           # text, select, multiselect, date
    has options: list = [];
    has required: bool = False;

    can create with `root entry {
        # Check if column already exists
        existing = [here --> (`?column_schema)];
        for col in existing {
            if col.name == self.name {
                report {"success": False, "message": f"Column '{self.name}' already exists"};
                disengage;
            }
        }

        # Get next order number
        order = len(existing);

        # Create column
        here ++> column_schema(
            name=self.name,
            type=self.type,
            options=self.options,
            required=self.required,
            order=order
        );

        report {
            "success": True,
            "message": f"Column '{self.name}' created",
            "column": {"name": self.name, "type": self.type, "options": self.options}
        };
    }
}

walker get_columns {
    can execute with `root entry {
        columns = [];
        for col in [here --> (`?column_schema)] {
            columns.append({
                "name": col.name,
                "type": col.type,
                "options": col.options,
                "required": col.required,
                "order": col.order
            });
        }

        # Sort by order
        columns.sort(key=lambda x: x["order"]);

        report {"success": True, "columns": columns};
    }
}

walker update_column {
    has name: str;
    has new_type: str = "";
    has new_options: list = [];

    can update with column_schema entry {
        if here.name == self.name {
            if self.new_type {
                here.type = self.new_type;
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

# ============ TASK MANAGEMENT ============

walker add_task {
    has fields: dict = {};  # Dynamic fields from frontend

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

walker get_tasks {
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

walker update_task {
    has task_id: str;  # Use a unique field value as ID (e.g., assignment name)
    has id_field: str = "assignment";  # Which field to use as identifier
    has fields: dict = {};

    can update with task entry {
        if self.id_field in here.fields and here.fields[self.id_field] == self.task_id {
            # Update fields
            for key, value in self.fields.items() {
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

# ============ SETUP DEFAULT COLUMNS ============

walker init_default_columns {
    can create with `root entry {
        # Check if columns already exist
        existing = [here --> (`?column_schema)];
        if len(existing) > 0 {
            report {"success": False, "message": "Columns already initialized"};
            disengage;
        }

        # Create default columns
        here ++> column_schema(
            name="assignment",
            type="text",
            required=True,
            order=0
        );

        here ++> column_schema(
            name="courses",
            type="multiselect",
            options=[],
            order=1
        );

        here ++> column_schema(
            name="status",
            type="select",
            options=["todo", "in progress", "done", "not started", "submitted"],
            order=2
        );

        here ++> column_schema(
            name="due_date",
            type="date",
            order=3
        );

        report {"success": True, "message": "Default columns created"};
    }
}
