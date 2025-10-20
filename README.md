# JAC Task Tracker

AI-powered task tracker with intelligent course classification using Claude 3.5 Sonnet.

## Quick Start

```bash
# Set API key
export ANTHROPIC_API_KEY="sk-ant-xxxxxxxxxxxxx"

# Start backend (Terminal 1)
./start_server.sh

# Start frontend (Terminal 2)
./start_frontend.sh
```

Open http://localhost:8501

## Features

- **AI Classification** - Automatically detects courses from task descriptions
- **Multi-select Courses** - Tasks can belong to multiple courses
- **Pattern Learning** - Gets smarter over time by tracking keywords
- **Web Interface** - Full-featured Streamlit UI with 4 pages
- **Statistics Dashboard** - Track completion rates and course distribution

## Model

Uses Claude 3.5 Sonnet (2024-10-22) for intelligent course detection.
Get your API key: https://console.anthropic.com/

## Files

- `server.jac` - Backend API (JAC Cloud/FastAPI)
- `frontend.jac` - Streamlit web interface
- `core.jac` - CLI data models
- `walkers.jac` - CLI business logic
- `main.jac` - CLI demo

## CLI Usage

```bash
source venv/bin/activate
jac run main.jac
```

## API Endpoints

- POST /walker/add_task - Add new task
- POST /walker/get_tasks - Get all tasks
- POST /walker/update_task - Update task
- POST /walker/delete_task - Delete task
- POST /walker/get_courses - Get courses
- POST /walker/get_stats - Get statistics

Docs: http://localhost:8000/docs
