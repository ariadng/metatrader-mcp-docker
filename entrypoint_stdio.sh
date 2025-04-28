#!/usr/bin/env bash
set -euo pipefail

# require credentials
: "${MT5_LOGIN:?Need MT5_LOGIN}"
: "${MT5_PASSWORD:?Need MT5_PASSWORD}"
: "${MT5_SERVER:?Need MT5_SERVER}"

# start Xvfb on :0 for Wine’s GUI needs
Xvfb :0 -screen 0 1024x768x24 -nolisten tcp &
export DISPLAY=:0
sleep 2

# exec the MCP STDIO server via Wine's Python
exec wine python.exe -m metatrader_mcp_server \
     --login    "$MT5_LOGIN" \
     --password "$MT5_PASSWORD" \
     --server   "$MT5_SERVER"
