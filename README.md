# JAC Task Tracker

AI-powered task tracker with intelligent course classification using Claude 3.5 Sonnet.

## Quick Start

```bash
./start.sh
```

This starts both backend (port 8000) and frontend (port 8501) automatically.

**Alternative**: Use `./start_server.sh` and `./start_frontend.sh` in separate terminals.

## Features

### AI Course Classification
- Course descriptions provide context clues for AI
- Learns from keywords and usage patterns
- Automatically classifies new tasks based on assignment name

### Task Management
- Click "➕ Add New Task" to create new row
- AI detects course when you enter assignment name
- Edit course/status with dropdowns
- Multi-select courses for cross-listed tasks

### Course Management
- Add courses with descriptions in sidebar
- Example: "EECS270: Logic design, circuits, gates, FSMs"
- Descriptions help AI classify tasks accurately

## Model

Uses Google Gemini 2.0 Flash for intelligent course detection.
Get your API key: https://aistudio.google.com/apikey

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

- POST /walker/add_task - Add new task (with AI classification)
- POST /walker/get_tasks - Get all tasks
- POST /walker/update_task - Update task
- POST /walker/delete_task - Delete task
- POST /walker/get_courses - Get courses
- POST /walker/add_course - Add course with description
- POST /walker/update_course - Update course details
- POST /walker/get_stats - Get statistics

Docs: http://localhost:8000/docs

## Configuration

Set your API key in `.env`:
```bash
export GEMINI_API_KEY="your-gemini-api-key"
```

Get your key from: https://aistudio.google.com/apikey
