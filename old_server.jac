include core;

import from byllm.llm { Model }

glob llm = Model(model_name="gemini/gemini-2.0-flash-exp", verbose=True);

def classify_task_to_courses(
    assignment_name: str,
    task_description: str,
    available_courses: list[CourseInfo]
) -> list[str] by llm(
    incl_info=(available_courses,)
);

walker add_task {
    has assignment: str;
    has due_date: str;
    has description: str = "";
    has status: str = "todo";
    has courses: list = [];
    has use_ai: bool = True;

    can create with `root entry {
        current_time = "2025-10-20T00:00:00";
        task_node = here ++> task(
            assignment=self.assignment,
            due_date=self.due_date,
            description=self.description,
            status=self.status,
            created_at=current_time
        );

        detected_courses = [];

        if len(self.courses) > 0 {
            detected_courses = self.courses;
        } elif self.use_ai {
            existing_courses_list = [here --> (`?course)];
            course_info = [];
            for c in existing_courses_list {
                course_info.append(
                    CourseInfo(
                        code=c.code,
                        title=c.title,
                        description=c.description,
                        usage_count=c.usage_count,
                        keywords=c.keywords
                    )
                );
            }

            if len(course_info) > 0 {
                detected_courses = classify_task_to_courses(
                    self.assignment,
                    self.description,
                    course_info
                );
            }
        }

        for course_code in detected_courses {
            all_courses = [here --> (`?course)];
            existing_course = None;

            for c in all_courses {
                if c.code == course_code {
                    existing_course = c;
                    break;
                }
            }

            if existing_course {
                existing_course.usage_count += 1;
                words = (self.assignment + " " + self.description).lower().split();
                for w in words {
                    if len(w) > 3 and w not in existing_course.keywords {
                        existing_course.keywords.append(w);
                    }
                }
            } else {
                keywords = [];
                words = (self.assignment + " " + self.description).lower().split();
                for w in words {
                    if len(w) > 3 {
                        keywords.append(w);
                    }
                }
                existing_course = here ++> course(
                    code=course_code,
                    title=course_code,
                    usage_count=1,
                    keywords=keywords[:10]
                );
            }

            task_node +>:belongs_to:+> existing_course;
        }

        report {
            "success": True,
            "message": f"Task '{self.assignment}' created successfully",
            "task": {
                "assignment": self.assignment,
                "due_date": self.due_date,
                "description": self.description,
                "status": self.status,
                "courses": detected_courses
            }
        };
    }
}

walker get_tasks {
    has tasks_list: list = [];

    can gather with task entry {
        task_courses = [];
        for edge in [-->] {
            if isinstance(edge, course) {
                task_courses.append(edge.code);
            }
        }

        task_info = {
            "assignment": here.assignment,
            "description": here.description,
            "due_date": here.due_date,
            "status": here.status,
            "courses": task_courses,
            "created_at": here.created_at
        };
        self.tasks_list.append(task_info);
    }

    can execute with `root entry {
        all_tasks = [here --> (`?task)];
        for t in all_tasks {
            visit t;
        }

        report {
            "success": True,
            "tasks": self.tasks_list,
            "count": len(self.tasks_list)
        };
    }
}

walker update_task {
    has assignment: str;
    has new_status: str = "";
    has new_due_date: str = "";
    has new_description: str = "";
    has updated: bool = False;

    can update with task entry {
        if here.assignment == self.assignment {
            if self.new_status {
                here.status = self.new_status;
            }
            if self.new_due_date {
                here.due_date = self.new_due_date;
            }
            if self.new_description {
                here.description = self.new_description;
            }
            self.updated = True;
        }
    }

    can execute with `root entry {
        all_tasks = [here --> (`?task)];
        for t in all_tasks {
            visit t;
        }

        if self.updated {
            report {
                "success": True,
                "message": f"Task '{self.assignment}' updated successfully"
            };
        } else {
            report {
                "success": False,
                "message": f"Task '{self.assignment}' not found"
            };
        }
    }
}

walker delete_task {
    has assignment: str;
    has deleted: bool = False;

    can remove with task entry {
        if here.assignment == self.assignment {
            del here;
            self.deleted = True;
        }
    }

    can execute with `root entry {
        all_tasks = [here --> (`?task)];
        for t in all_tasks {
            visit t;
        }

        if self.deleted {
            report {
                "success": True,
                "message": f"Task '{self.assignment}' deleted successfully"
            };
        } else {
            report {
                "success": False,
                "message": f"Task '{self.assignment}' not found"
            };
        }
    }
}

walker get_courses {
    has courses_list: list = [];

    can gather with course entry {
        course_info = {
            "code": here.code,
            "title": here.title,
            "description": here.description,
            "usage_count": here.usage_count,
            "keywords": here.keywords
        };
        self.courses_list.append(course_info);
    }

    can execute with `root entry {
        all_courses = [here --> (`?course)];
        for c in all_courses {
            visit c;
        }

        report {
            "success": True,
            "courses": self.courses_list,
            "count": len(self.courses_list)
        };
    }
}

walker get_stats {
    can execute with `root entry {
        all_tasks = [here --> (`?task)];
        all_courses = [here --> (`?course)];

        status_counts = {};
        for t in all_tasks {
            status = t.status;
            if status in status_counts {
                status_counts[status] += 1;
            } else {
                status_counts[status] = 1;
            }
        }

        report {
            "success": True,
            "total_tasks": len(all_tasks),
            "total_courses": len(all_courses),
            "status_breakdown": status_counts
        };
    }
}

walker add_course {
    has code: str;
    has title: str;
    has description: str = "";

    can create with `root entry {
        all_courses = [here --> (`?course)];
        for c in all_courses {
            if c.code == self.code {
                report {
                    "success": False,
                    "message": f"Course '{self.code}' already exists"
                };
                disengage;
            }
        }

        new_course = here ++> course(
            code=self.code,
            title=self.title,
            description=self.description,
            usage_count=0,
            keywords=[]
        );

        report {
            "success": True,
            "message": f"Course '{self.code}' created successfully",
            "course": {
                "code": self.code,
                "title": self.title,
                "description": self.description
            }
        };
    }
}

walker update_course {
    has code: str;
    has title: str = "";
    has description: str = "";
    has updated: bool = False;

    can update with course entry {
        if here.code == self.code {
            if self.title {
                here.title = self.title;
            }
            if self.description {
                here.description = self.description;
            }
            self.updated = True;
        }
    }

    can execute with `root entry {
        all_courses = [here --> (`?course)];
        for c in all_courses {
            visit c;
        }

        if self.updated {
            report {
                "success": True,
                "message": f"Course '{self.code}' updated successfully"
            };
        } else {
            report {
                "success": False,
                "message": f"Course '{self.code}' not found"
            };
        }
    }
}

walker delete_course {
    has code: str;
    has deleted: bool = False;

    can remove with course entry {
        if here.code == self.code {
            del here;
            self.deleted = True;
        }
    }

    can execute with `root entry {
        all_courses = [here --> (`?course)];
        for c in all_courses {
            visit c;
        }

        if self.deleted {
            report {
                "success": True,
                "message": f"Course '{self.code}' deleted successfully"
            };
        } else {
            report {
                "success": False,
                "message": f"Course '{self.code}' not found"
            };
        }
    }
}