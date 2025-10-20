include core;

# Walker to add a new task with automatic course classification
walker add_task {
    has assignment: str;
    has due_date: str;
    has description: str = "";
    has status: str = "todo";
    has courses: list = [];  # Optional: user can specify courses manually

    can create with `root entry {
        # Create task node
        current_time = "2025-10-20T00:00:00";
        task_node = root ++> task(
            assignment=self.assignment,
            description=self.description,
            due_date=self.due_date,
            status=self.status,
            created_at=current_time
        );

        # If user specified courses manually, use them
        if len(self.courses) > 0 {
            for course_code in self.courses {
                # Find or create course
                all_courses = [root --> (`?course)];
                existing_course = None;

                for c in all_courses {
                    if c.code == course_code {
                        existing_course = c;
                        break;
                    }
                }

                if existing_course {
                    existing_course.usage_count += 1;
                } else {
                    existing_course = root ++> course(
                        code=course_code,
                        title=course_code,
                        usage_count=1
                    );
                }

                task_node +>:belongs_to:+> existing_course;
            }
        } else {
            # Auto-classify by keywords
            text = (self.assignment + " " + self.description).lower();
            detected_courses = [];

            # Simple keyword matching
            if "cs161" in text or "cs 161" in text or "computer" in text {
                detected_courses.append("CS161");
            }
            if "robojackets" in text or "robo" in text or "robot" in text {
                detected_courses.append("RoboJackets");
            }
            if "personal" in text or "gym" in text or "workout" in text {
                detected_courses.append("Personal");
            }
            if "math" in text {
                detected_courses.append("MATH");
            }

            # Default if nothing detected
            if len(detected_courses) == 0 {
                if "homework" in text or "problem" in text or "study" in text {
                    detected_courses.append("Academic");
                } else {
                    detected_courses.append("General");
                }
            }

            # Create/update courses
            for course_code in detected_courses {
                all_courses = [root --> (`?course)];
                existing_course = None;

                for c in all_courses {
                    if c.code == course_code {
                        existing_course = c;
                        break;
                    }
                }

                if existing_course {
                    existing_course.usage_count += 1;
                    # Add keywords
                    words = text.split();
                    for w in words {
                        if len(w) > 3 and w not in existing_course.keywords {
                            existing_course.keywords.append(w);
                        }
                    }
                } else {
                    # Extract keywords
                    keywords = [];
                    words = text.split();
                    for w in words {
                        if len(w) > 3 {
                            keywords.append(w);
                        }
                    }
                    existing_course = root ++> course(
                        code=course_code,
                        title=course_code,
                        usage_count=1,
                        keywords=keywords[:10]
                    );
                }

                task_node +>:belongs_to:+> existing_course;
            }
        }

        print(f"Task created: {self.assignment} (due: {self.due_date})");
    }
}

# Walker to get all tasks with their courses
walker get_all_tasks {
    has tasks_list: list = [];

    can gather with task entry {
        # Get courses for this task
        task_courses = [];
        # Get all connected course nodes
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
}

# Walker to update task status
walker update_task_status {
    has assignment: str;
    has new_status: str;

    can update with task entry {
        if here.assignment == self.assignment {
            here.status = self.new_status;
            print(f"Updated task '{self.assignment}' status to '{self.new_status}'");
        }
    }
}

# Walker to get all courses
walker get_all_courses {
    has courses_list: list = [];

    can gather with course entry {
        course_info = {
            "code": here.code,
            "title": here.title,
            "usage_count": here.usage_count,
            "keywords": here.keywords
        };
        self.courses_list.append(course_info);
    }
}
