# Dockerfile — Ubuntu 24.04 + Wine + MetaTrader 5 + MCP Server (STDIO)
FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive

# 1) Install WineHQ, Xvfb, winbind, and CA certs for HTTPS downloads
RUN dpkg --add-architecture i386 \
 && apt-get update \
 && apt-get install -y \
      wget \
      ca-certificates \
      gnupg2 \
      software-properties-common \
 && mkdir -pm755 /etc/apt/keyrings \
 && wget -O /etc/apt/keyrings/winehq-archive.key \
      https://dl.winehq.org/wine-builds/winehq.key \
 && echo "deb [signed-by=/etc/apt/keyrings/winehq-archive.key] \
      https://dl.winehq.org/wine-builds/ubuntu/ $(lsb_release -cs) main" \
      > /etc/apt/sources.list.d/winehq.list \
 && apt-get update \
 && apt-get install -y --install-recommends \
      winehq-stable \
      winbind \
      xvfb \
 && rm -rf /var/lib/apt/lists/*

# 2) Create a non-root 'wine' user
RUN groupadd wine \
 && useradd -m -s /bin/bash -g wine wine \
 && mkdir -p /home/wine/.wine \
 && chown -R wine:wine /home/wine

USER wine
ENV WINEARCH=win64 \
    WINEPREFIX=/home/wine/.wine

# 3) Initialize Wine prefix
RUN wineboot --init \
 && wineserver -w

# 4) Install MetaTrader 5 silently
RUN wget -O /tmp/mt5setup.exe \
      "https://download.mql5.com/cdn/web/metaquotes.ltd/mt5/mt5setup.exe" \
 && wine /tmp/mt5setup.exe /quiet InstallAllUsers=1 PrependPath=1 \
 && wineserver -w \
 && rm /tmp/mt5setup.exe

# 5) Install Windows-Python 3.10 + pip under Wine
RUN wget -O /tmp/python-installer.exe \
      "https://www.python.org/ftp/python/3.10.12/python-3.10.12-amd64.exe" \
 && wine /tmp/python-installer.exe \
      /quiet InstallAllUsers=1 PrependPath=1 Include_pip=1 \
 && wineserver -w \
 && rm /tmp/python-installer.exe

# 6) Install MCP STDIO + MetaTrader5 wrapper into Wine’s Python
RUN wine pip install --no-cache-dir metatrader-mcp-server MetaTrader5 \
 && wineserver -w

# 7) Copy in STDIO entrypoint
USER root
COPY entrypoint_stdio.sh /usr/local/bin/entrypoint_stdio.sh
RUN chmod +x /usr/local/bin/entrypoint_stdio.sh

# 8) Switch back to 'wine' user and set entrypoint
USER wine
ENTRYPOINT ["/usr/local/bin/entrypoint_stdio.sh"]
