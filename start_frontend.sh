#!/bin/bash

echo "🎨 Starting Frontend..."
echo ""

# Load .env if it exists
if [ -f .env ]; then
    source .env
fi

if ! curl -s http://localhost:8000 > /dev/null 2>&1; then
    echo "⚠️  Backend not running!"
    echo "Start it first: ./start_server.sh"
    echo ""
    read -p "Continue anyway? [y/N]: " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

source venv/bin/activate

echo "🌐 Frontend starting on http://localhost:8501"
echo ""

streamlit run run_frontend.py
