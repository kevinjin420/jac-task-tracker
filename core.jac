node user {
    has name;
}

node course {
    has code;
    has title;
}

node tag {
    has name;
    has frequency = 0;
}

node task {
    has title;
    has description;
    has due_date;
    has status;
}

edge assigned_to;
edge belongs_to;
