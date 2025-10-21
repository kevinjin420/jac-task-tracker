#!/bin/bash

echo "🚀 Starting Backend Server..."
echo ""

# Load .env if it exists
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

echo "🌐 Server starting on http://localhost:8000"
echo "📚 API docs at http://localhost:8000/docs"
echo ""

jac serve server.jac
