walker add_and_tag_task {
    has title: string;
    has category: string;
    has due_date: int;
    has status: string;

    spawn add_task(
        title=title,
        description=description,
        due_date=due_date,
        status=status
    );
}
