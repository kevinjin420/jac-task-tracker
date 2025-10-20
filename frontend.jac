import streamlit as st;
import requests;
import json;

def bootstrap_frontend(token: str) {
    st.set_page_config(
        page_title="Assignment Tracker",
        page_icon="📚",
        layout="wide"
    );

    st.markdown("""
    <style>
    .main { padding: 1rem; background-color: #1a1a1a; }
    .stButton>button { width: 100%; }
    h1 { color: #ffffff; font-size: 1.5rem; margin-bottom: 1rem; }

    /* Table styles */
    .task-table {
        width: 100%;
        border-collapse: collapse;
        background-color: #1a1a1a;
        color: #ffffff;
        font-size: 14px;
    }
    .task-table th {
        text-align: left;
        padding: 8px 12px;
        font-weight: 500;
        color: #888888;
        border-bottom: 1px solid #2a2a2a;
        font-size: 12px;
    }
    .task-table td {
        padding: 8px 12px;
        border-bottom: 1px solid #2a2a2a;
    }
    .task-table tr:hover {
        background-color: #252525;
    }

    /* Course tags */
    .course-tag {
        display: inline-block;
        padding: 2px 8px;
        border-radius: 3px;
        font-size: 12px;
        font-weight: 500;
        margin-right: 4px;
    }
    .course-EECS270 { background-color: #7c3c00; color: #ffa940; }
    .course-EECS481 { background-color: #0d5c3f; color: #4ade80; }
    .course-EECS485 { background-color: #1e4a7c; color: #60a5fa; }
    .course-JASECI { background-color: #7c5c00; color: #fbbf24; }
    .course-EECS201 { background-color: #7c3c00; color: #ffa940; }
    .course-EECS215 { background-color: #7c1c3f; color: #fb7185; }
    .course-PERSONAL { background-color: #4a4a4a; color: #d4d4d4; }
    .course-MROVER { background-color: #5c1e7c; color: #c084fc; }
    .course-default { background-color: #4a4a4a; color: #d4d4d4; }

    /* Status badges */
    .status-badge {
        display: inline-block;
        padding: 2px 8px;
        border-radius: 3px;
        font-size: 12px;
        font-weight: 500;
    }
    .status-submitted { background-color: #0d5c3f; color: #4ade80; }
    .status-in-progress { background-color: #7c5c00; color: #fbbf24; }
    .status-not-started { background-color: #7c1c1c; color: #fb7185; }
    .status-perpetual { background-color: #4a4a4a; color: #d4d4d4; }
    .status-todo { background-color: #4a4a4a; color: #d4d4d4; }
    .status-done { background-color: #0d5c3f; color: #4ade80; }
    .status-blocked { background-color: #7c1c1c; color: #fb7185; }

    /* Hide streamlit elements */
    #MainMenu {visibility: hidden;}
    footer {visibility: hidden;}
    header {visibility: hidden;}
    </style>
    """, unsafe_allow_html=True);

    if "tasks" not in st.session_state {
        st.session_state.tasks = [];
    }
    if "courses" not in st.session_state {
        st.session_state.courses = [];
    }

    if st.session_state.get("refresh", True) {
        try {
            response = requests.post(
                "http://localhost:8000/walker/get_tasks",
                json={},
                headers={"Authorization": f"Bearer {token}"}
            );
            if response.status_code == 200 {
                result = response.json().get("reports", [{}])[0];
                st.session_state.tasks = result.get("tasks", []);
            }

            response = requests.post(
                "http://localhost:8000/walker/get_courses",
                json={},
                headers={"Authorization": f"Bearer {token}"}
            );
            if response.status_code == 200 {
                result = response.json().get("reports", [{}])[0];
                st.session_state.courses = result.get("courses", []);
            }

            st.session_state.refresh = False;
        } except Exception as e {
            st.error(f"Failed to fetch data: {str(e)}");
        }
    }

    st.title("📋 Assignment Tracker");

    with st.sidebar {
        st.markdown("### ➕ Add Task");

        assignment = st.text_input("Assignment", placeholder="e.g., p5");

        course_options = list(set([c["code"] for c in st.session_state.courses])) + ["EECS270", "EECS481", "EECS485", "JASECI", "EECS201", "PERSONAL"];
        course = st.selectbox("Course", course_options);

        status = st.selectbox("Status", ["todo", "in progress", "done", "not started", "submitted"]);

        due_date = st.date_input("Due Date");

        if st.button("Add Task") {
            if assignment and due_date {
                try {
                    response = requests.post(
                        "http://localhost:8000/walker/add_task",
                        json={
                            "assignment": assignment,
                            "due_date": str(due_date),
                            "status": status,
                            "courses": [course],
                            "use_ai": False
                        },
                        headers={"Authorization": f"Bearer {token}"}
                    );

                    if response.status_code == 200 {
                        st.success("Task added!");
                        st.session_state.refresh = True;
                        st.rerun();
                    }
                } except Exception as e {
                    st.error(f"Error: {str(e)}");
                }
            }
        }

        st.markdown("---");

        if st.button("🔄 Refresh") {
            st.session_state.refresh = True;
            st.rerun();
        }
    }

    if len(st.session_state.tasks) == 0 {
        st.info("No tasks yet. Add your first task using the sidebar!");
    } else {
        table_html = '<table class="task-table"><thead><tr>';
        table_html += '<th>Course</th>';
        table_html += '<th>Assignment</th>';
        table_html += '<th>Status</th>';
        table_html += '<th>Due Date</th>';
        table_html += '</tr></thead><tbody>';

        for task in st.session_state.tasks {
            table_html += '<tr>';

            courses = task.get("courses", []);
            if len(courses) > 0 {
                course_html = '';
                for c in courses {
                    course_class = f"course-{c}";
                    course_html += f'<span class="course-tag {course_class}">{c}</span>';
                }
                table_html += f'<td>{course_html}</td>';
            } else {
                table_html += '<td></td>';
            }

            table_html += f'<td>📄 {task.get("assignment", "")}</td>';

            status_val = task.get("status", "todo");
            status_class = f"status-{status_val.replace(' ', '-')}";
            status_display = status_val.title();
            if status_val == "not started" {
                status_display = "Not started";
            } elif status_val == "in progress" {
                status_display = "In progress";
            } elif status_val == "todo" {
                status_display = "To do";
            }
            table_html += f'<td><span class="status-badge {status_class}">{status_display}</span></td>';

            table_html += f'<td>{task.get("due_date", "")}</td>';

            table_html += '</tr>';
        }

        table_html += '</tbody></table>';

        st.markdown(table_html, unsafe_allow_html=True);
    }
}

with entry {
    INSTANCE_URL = "http://localhost:8000";
    TEST_USER_EMAIL = "user@tasktracker.com";
    TEST_USER_PASSWORD = "password123";

    response = requests.post(
        f"{INSTANCE_URL}/user/login",
        json={"email": TEST_USER_EMAIL, "password": TEST_USER_PASSWORD}
    );

    if response.status_code != 200 {
        response = requests.post(
            f"{INSTANCE_URL}/user/register",
            json={
                "email": TEST_USER_EMAIL,
                "password": TEST_USER_PASSWORD
            }
        );

        if response.status_code == 201 {
            response = requests.post(
                f"{INSTANCE_URL}/user/login",
                json={"email": TEST_USER_EMAIL, "password": TEST_USER_PASSWORD}
            );
        }
    }

    if response.status_code == 200 {
        token = response.json()["token"];
        bootstrap_frontend(token);
    } else {
        st.error("Failed to authenticate. Make sure the server is running: `jac serve server.jac`");
    }
}
