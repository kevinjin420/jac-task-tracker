import from schema { ColumnType, task, category_store }
import from byllm.llm {Model}
import from datetime {datetime, timedelta}

glob llm = Model(model_name="gemini/gemini-2.0-flash-exp", verbose=True);

def categorize_task(task_name: str, categories: list[dict]) -> str by llm(
    incl_info=(categories,)
);

walker get_columns {
    obj __specs__ {
        static has auth: bool = False;
    }

    can execute with `root entry {
        category_stores = [here --> (`?category_store)];
        category_opts = [];
        if len(category_stores) == 0 {
            default_opts = [
                {"name": "EECS270", "context": "course on circuits"},
                {"name": "EECS370", "context": "course on computer organization"},
                {"name": "General", "context": "general tasks not related to any specific course"}
            ];
            here ++> category_store(options=default_opts);
            category_opts = default_opts;
        } else {
            category_opts = category_stores[0].options;
        }

        hardcoded_columns = [
            {
                "name": "category",
                "type": ColumnType.MULTISELECT.name,
                "options": category_opts,
                "order": 0
            },
            {
                "name": "name",
                "type": ColumnType.TEXT.name,
                "options": [],
                "order": 1
            },
            {
                "name": "status",
                "type": ColumnType.SELECT.name,
                "options": ["not started", "in progress", "done"],
                "order": 2
            },
            {
                "name": "due_date",
                "type": ColumnType.DATE.name,
                "options": [],
                "order": 3
            }
        ];
        report {"success": True, "columns": hardcoded_columns};
    }
}

walker update_category_options {
    obj __specs__ {
        static has auth: bool = False;
    }

    has new_options: list;

    can execute with `root entry {
        category_stores = [here --> (`?category_store)];
        if len(category_stores) == 0 {
            here ++> category_store(options=self.new_options);
        } else {
            category_stores[0].options = self.new_options;
        }
        report {"success": True, "message": "Category options updated"};
    }
}

walker add_task {
    obj __specs__ {
        static has auth: bool = False;
    }

    has task_name: str;

    can create with `root entry {
        category_stores = [here --> (`?category_store)];
        suggested_category = "General";

        if len(category_stores) > 0 and len(category_stores[0].options) > 0 {
            ai_category = categorize_task(self.task_name, category_stores[0].options);
            suggested_category = ai_category.strip();

            valid_category_names = [cat["name"] for cat in category_stores[0].options];
            if suggested_category not in valid_category_names {
                suggested_category = "General";
            }
        }

        now = datetime.now();
        tomorrow = now + timedelta(days=1);
        current_time = now.strftime("%Y-%m-%dT%H:%M:%S");
        due_date = tomorrow.strftime("%Y-%m-%d");

        new_task_nodes = here ++> task(
            name=self.task_name,
            category=[suggested_category],
            status="not started",
            due_date=due_date,
            created_at=current_time
        );

        new_task_node = new_task_nodes[0];

        report {
            "success": True,
            "message": "Task created with AI category",
            "task": {
                "fields": {
                    "name": new_task_node.name,
                    "category": new_task_node.category,
                    "status": new_task_node.status,
                    "due_date": new_task_node.due_date
                },
                "created_at": new_task_node.created_at
            }
        };
    }
}

walker update_task {
    obj __specs__ {
        static has auth: bool = False;
    }

    has task_id: str;
    has id_field: str = "name";
    has fields: dict = {};

    can update with task entry {
        if self.id_field == "name" and here.name == self.task_id {
            for (key, value) in self.fields.items() {
                if key == "name" {
                    here.name = value;
                } elif key == "category" {
                    here.category = value;
                } elif key == "status" {
                    here.status = value;
                } elif key == "due_date" {
                    here.due_date = value;
                }
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
    obj __specs__ {
        static has auth: bool = False;
    }

    has task_id: str;
    has id_field: str = "name";
    can remove with task entry {
        if self.id_field == "name" and here.name == self.task_id {
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
    obj __specs__ {
        static has auth: bool = False;
    }

    can execute with `root entry {
        tasks = [];
        for t in [here --> (`?task)] {
            tasks.append({
                "fields": {
                    "name": t.name,
                    "category": t.category,
                    "status": t.status,
                    "due_date": t.due_date
                },
                "created_at": t.created_at
            });
        }

        report {"success": True, "tasks": tasks};
    }
}

walker clear_all_tasks {
    obj __specs__ {
        static has auth: bool = False;
    }

    can execute with `root entry {
        all_tasks = [here --> (`?task)];
        for t in all_tasks {
            del t;
        }
        report {"success": True, "message": f"Deleted {len(all_tasks)} tasks"};
    }
}
