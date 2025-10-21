import streamlit as st;
import requests;

def bootstrap_frontend(token: str) {
    st.set_page_config(
        page_title="Assignment Tracker",
        page_icon="📚",
        layout="wide"
    );

    if "tasks" not in st.session_state {
        st.session_state.tasks = [];
    }
    if "courses" not in st.session_state {
        st.session_state.courses = [];
    }
    if "new_row_active" not in st.session_state {
        st.session_state.new_row_active = False;
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

    st.title("Assignment Tracker");

    if st.button("➕ Add New Task") {
        st.session_state.new_row_active = True;
        st.rerun();
    }

    st.markdown("---");

    header_cols = st.columns([3, 2, 2, 2, 1]);
    header_cols[0].markdown("**Assignment**");

    courses_popover = header_cols[1].popover("**Courses ⚙️**");
    courses_popover.markdown("### Manage Courses");

    new_course_code = courses_popover.text_input("Course Code", key="new_course_code", placeholder="EECS270");
    new_course_title = courses_popover.text_input("Course Title", key="new_course_title", placeholder="Intro to Logic Design");
    new_course_desc = courses_popover.text_area("Description", key="new_course_desc", placeholder="Topics: circuits, gates, FSMs...");

    if courses_popover.button("➕ Add Course", key="add_course_btn") {
        if new_course_code {
            try {
                response = requests.post(
                    "http://localhost:8000/walker/add_course",
                    json={
                        "code": new_course_code,
                        "title": new_course_title,
                        "description": new_course_desc
                    },
                    headers={"Authorization": f"Bearer {token}"}
                );
                if response.status_code == 200 {
                    st.session_state.refresh = True;
                    st.rerun();
                }
            } except Exception as e {
                courses_popover.error(f"Error: {str(e)}");
            }
        }
    }

    courses_popover.markdown("---");
    courses_popover.markdown("### Existing Courses");

    for course in st.session_state.courses {
        course_cols = courses_popover.columns([3, 1, 1]);
        course_cols[0].markdown(f"**{course.get('code')}**");
        course_cols[0].caption(f"{course.get('title', '')}");

        if course_cols[1].button("✏️", key=f"edit_course_{course.get('code')}") {
            st.session_state.editing_course = course.get('code');
        }

        if course_cols[2].button("🗑", key=f"del_course_{course.get('code')}") {
            try {
                response = requests.post(
                    "http://localhost:8000/walker/delete_course",
                    json={"code": course.get('code')},
                    headers={"Authorization": f"Bearer {token}"}
                );
                if response.status_code == 200 {
                    st.session_state.refresh = True;
                    st.rerun();
                }
            } except Exception as e {
                courses_popover.error(f"Error: {str(e)}");
            }
        }

        if st.session_state.get("editing_course") == course.get('code') {
            edit_title = courses_popover.text_input("Title", value=course.get('title', ''), key=f"edit_title_{course.get('code')}");
            edit_desc = courses_popover.text_area("Description", value=course.get('description', ''), key=f"edit_desc_{course.get('code')}");

            edit_cols = courses_popover.columns(2);
            if edit_cols[0].button("💾 Save", key=f"save_course_{course.get('code')}") {
                try {
                    response = requests.post(
                        "http://localhost:8000/walker/update_course",
                        json={
                            "code": course.get('code'),
                            "title": edit_title,
                            "description": edit_desc
                        },
                        headers={"Authorization": f"Bearer {token}"}
                    );
                    if response.status_code == 200 {
                        st.session_state.editing_course = None;
                        st.session_state.refresh = True;
                        st.rerun();
                    }
                } except Exception as e {
                    courses_popover.error(f"Error: {str(e)}");
                }
            }
            if edit_cols[1].button("✕", key=f"cancel_edit_{course.get('code')}") {
                st.session_state.editing_course = None;
                st.rerun();
            }
        }
    }

    status_popover = header_cols[2].popover("**Status ⚙️**");
    status_popover.markdown("### Manage Status Options");
    status_popover.info("Status options are currently hardcoded. Custom statuses coming soon!");
    status_popover.markdown("**Current statuses:**");
    status_popover.markdown("- todo");
    status_popover.markdown("- in progress");
    status_popover.markdown("- done");
    status_popover.markdown("- not started");
    status_popover.markdown("- submitted");

    header_cols[3].markdown("**Due Date**");
    header_cols[4].markdown("**Actions**");

    if st.session_state.get("new_row_active", False) {
        form = st.form("new_task_form");
        cols = form.columns([3, 2, 2, 2, 1]);

        new_assignment = cols[0].text_input("Assignment", key="new_assignment", placeholder="Enter assignment name", label_visibility="collapsed");

        submit_clicked = form.form_submit_button("✓");
        cancel_clicked = cols[4].form_submit_button("✕");

        if cancel_clicked {
            st.session_state.new_row_active = False;
            st.rerun();
        }

        if submit_clicked and new_assignment and new_assignment.strip() {
            try {
                response = requests.post(
                    "http://localhost:8000/walker/add_task",
                    json={
                        "assignment": new_assignment,
                        "due_date": "2025-12-31",
                        "status": "todo",
                        "description": "",
                        "use_ai": True
                    },
                    headers={"Authorization": f"Bearer {token}"}
                );

                if response.status_code == 200 {
                    st.session_state.new_row_active = False;
                    st.session_state.refresh = True;
                    st.rerun();
                }
            } except Exception as e {
                st.error(f"Error: {str(e)}");
            }
        }
    }

    course_options = list(set([c["code"] for c in st.session_state.courses]));
    status_options = ["todo", "in progress", "done", "not started", "submitted"];

    idx = 0;
    for task in st.session_state.tasks {
        cols = st.columns([3, 2, 2, 2, 1]);

        task_key = f"task_{idx}";

        cols[0].text_input("Assignment", value=task.get("assignment", ""), key=f"{task_key}_name", disabled=True, label_visibility="collapsed");

        current_courses = task.get("courses", []);
        selected_courses = cols[1].multiselect(
            "Courses",
            course_options,
            default=current_courses,
            key=f"{task_key}_courses",
            label_visibility="collapsed"
        );

        current_status = task.get("status", "todo");
        selected_status = cols[2].selectbox(
            "Status",
            status_options,
            index=status_options.index(current_status) if current_status in status_options else 0,
            key=f"{task_key}_status",
            label_visibility="collapsed"
        );

        current_due = task.get("due_date", "2025-12-31");
        cols[3].text_input("Due Date", value=current_due, key=f"{task_key}_due", disabled=True, label_visibility="collapsed");

        if cols[4].button("🗑", key=f"{task_key}_delete") {
            try {
                response = requests.post(
                    "http://localhost:8000/walker/delete_task",
                    json={"assignment": task.get("assignment")},
                    headers={"Authorization": f"Bearer {token}"}
                );
                if response.status_code == 200 {
                    st.session_state.refresh = True;
                    st.rerun();
                }
            } except Exception as e {
                st.error(f"Error: {str(e)}");
            }
        }

        idx += 1;
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
        st.error("Failed to authenticate. Start server: ./start_server.sh");
    }
}
