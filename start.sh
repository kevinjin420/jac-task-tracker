#!/bin/bash

echo "🚀 Starting JAC Task Tracker"
echo ""

if [ -f .env ]; then
    source .env
    echo "✓ Loaded .env file"
fi

if [ -z "$GEMINI_API_KEY" ]; then
    echo "⚠️  GEMINI_API_KEY not set!"
    echo "Set it in .env file or export GEMINI_API_KEY='your-key'"
    echo "Get key from: https://aistudio.google.com/apikey"
    echo ""
    read -p "Continue anyway? [y/N]: " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

source venv/bin/activate

echo "🌐 Starting backend on http://localhost:8000"
jac serve server.jac &
SERVER_PID=$!

echo "⏳ Waiting for backend..."
for i in {1..30}; do
    if curl -s http://localhost:8000 > /dev/null 2>&1; then
        echo "✓ Backend ready"
        break
    fi
    sleep 1
done

echo ""
echo "🎨 Starting frontend on http://localhost:8501"
streamlit run run_frontend.py &
FRONTEND_PID=$!

echo ""
echo "✓ Both services started"
echo "  Backend:  http://localhost:8000"
echo "  Frontend: http://localhost:8501"
echo ""
echo "Press Ctrl+C to stop both services"

trap "kill $SERVER_PID $FRONTEND_PID 2>/dev/null; exit" INT TERM

wait
