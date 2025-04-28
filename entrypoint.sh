#!/bin/bash
# entrypoint.sh: Launch Xvfb and MetaTrader MCP HTTP server

# Require MT5 credentials in environment
if [[ -z "$MT5_LOGIN" || -z "$MT5_PASSWORD" || -z "$MT5_SERVER" ]]; then
  echo "Error: MT5_LOGIN, MT5_PASSWORD, and MT5_SERVER env variables must be set."
  exit 1
fi

# Start Xvfb on display :0 in the background
Xvfb :0 -screen 0 1024x768x24 -nolisten tcp &
XVFB_PID=$!
export DISPLAY=:0

# Give Xvfb a moment to start
sleep 2

# Run the MetaTrader MCP HTTP server (listening on all interfaces)
HTTP_PORT=${HTTP_PORT:-8000}
exec metatrader-http-server --login "$MT5_LOGIN" --password "$MT5_PASSWORD" --server "$MT5_SERVER" --host 0.0.0.0 --port "$HTTP_PORT"
