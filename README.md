# MetaTrader MCP Docker Container

## Build Docker

```bash
docker build -t metatrader-mcp:latest .
```

## Running The Container

```bash
docker run -d --name mt5_mcp_server \
  -e MT5_LOGIN=<YOUR_LOGIN> \
  -e MT5_PASSWORD=<YOUR_PASSWORD> \
  -e MT5_SERVER=<YOUR_SERVER_NAME> \
  -p 8000:8000 \
  metatrader-mcp:latest
```