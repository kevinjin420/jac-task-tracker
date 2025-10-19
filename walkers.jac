walker add_task {
    has title;
    has description;
    has due_date;
    has status = "todo";

    task_node = spawn task(title=title, description=description, due_date=due_date, status=status);
    connect root -[assigned_to]-> task_node;

    // Trigger AI tagging
    spawn auto_tag_task(target=task_node);
}

walker auto_tag_task {
    can task;

    // ByLLM classification
    result = byllm.call(
        model="task_tagger",
        prompt=f"""
        Classify the following task into a category (course code or project tag):
        Task: "{here.title}"
        Description: "{here.description}"
        Return JSON: {{ "tag": "<category>" }}
        """
    );

    if "tag" in result:
        tag_name = result["tag"];
        tag_node = spawn tag(name=tag_name);
        connect here -[belongs_to]-> tag_node;
}
