# Quick Start

## 1. Set API Key

```bash
export ANTHROPIC_API_KEY="sk-ant-xxxxxxxxxxxxx"
```

Get key: https://console.anthropic.com/

## 2. Start Backend

```bash
./start_server.sh
```

Wait for: `INFO: Uvicorn running on http://0.0.0.0:8000`

## 3. Start Frontend

Open new terminal:

```bash
./start_frontend.sh
```

Wait for: `Local URL: http://localhost:8501`

## 4. Open Browser

Navigate to: http://localhost:8501

## Troubleshooting

**Connection refused**: Start backend first
**API key not found**: Set ANTHROPIC_API_KEY
**Port in use**: `lsof -i :8000` and kill process

## Stop

Press Ctrl+C in both terminals
