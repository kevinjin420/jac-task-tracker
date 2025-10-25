include core;
include walkers;

# Main entry point - demonstrates the task tracker functionality
with entry {
    print("=== JAC Task Tracker with AI Course Classification ===\n");

    # Example 1: Add a task with AI auto-classification
    print("Example 1: Adding CS homework with auto-classification...");
    root spawn add_task(
        assignment="Finish problem set 3",
        description="Complete dynamic programming problems for CS161",
        due_date="2025-10-25",
        status="todo"
    );

    # Example 2: Add a task with manual course specification
    print("\nExample 2: Adding task with manual course...");
    root spawn add_task(
        assignment="Weekly team standup",
        description="Prepare update for RoboJackets meeting",
        due_date="2025-10-22",
        status="todo",
        courses=["RoboJackets"]
    );

    # Example 3: Add another CS task (AI should learn the pattern)
    print("\nExample 3: Adding another CS task (AI learning)...");
    root spawn add_task(
        assignment="Study for midterm",
        description="Review CS161 lecture notes on algorithms",
        due_date="2025-10-27",
        status="in progress"
    );

    # Example 4: Personal task
    print("\nExample 4: Adding personal task...");
    root spawn add_task(
        assignment="Gym workout",
        description="Leg day at the fitness center",
        due_date="2025-10-21",
        status="todo",
        courses=["Personal"]
    );

    # Get all tasks
    print("\n=== All Tasks ===");
    task_lister = get_all_tasks();
    all_tasks = [root --> (`?task)];
    for t in all_tasks {
        t spawn task_lister;
    }

    for task_info in task_lister.tasks_list {
        print(f"\nAssignment: {task_info['assignment']}");
        print(f"  Courses: {', '.join(task_info['courses'])}");
        print(f"  Status: {task_info['status']}");
        print(f"  Due: {task_info['due_date']}");
    }

    print("\n=== Task Tracker Ready! ===");
}
