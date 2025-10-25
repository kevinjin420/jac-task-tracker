#!/bin/bash

set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
VENV_PATH="$PROJECT_DIR/venv"

trap 'kill $BACKEND_PID $FRONTEND_PID 2>/dev/null; exit' SIGINT SIGTERM

cd "$PROJECT_DIR/backend"
"$VENV_PATH/bin/jac" serve main.jac &
BACKEND_PID=$!

echo "Waiting for backend to initialize..."
until curl -s http://localhost:8000 > /dev/null 2>&1; do
    sleep 0.5
done

cd "$PROJECT_DIR/frontend"
bun run dev &
FRONTEND_PID=$!

echo "Backend: http://localhost:8000 (PID: $BACKEND_PID)"
echo "Frontend: http://localhost:5173 (PID: $FRONTEND_PID)"

wait
