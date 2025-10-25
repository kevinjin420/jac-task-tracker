"""
main.jac - Entry point for the task tracker backend

This file includes all modules and serves as the main application entry point.
The Jac server will automatically expose walkers as API endpoints.

API Endpoints (auto-generated from walkers):
- POST /walker/init_default_columns
- POST /walker/get_columns
- POST /walker/add_column
- POST /walker/update_column
- POST /walker/delete_column
- POST /walker/get_tasks
- POST /walker/add_task
- POST /walker/update_task
- POST /walker/delete_task
"""

import walkers;
