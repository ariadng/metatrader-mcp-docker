# Dockerfile — Ubuntu 24.04 + Wine + MT5 + MCP STDIO

FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive \
    XDG_RUNTIME_DIR=/tmp/runtime

# 1) System deps, WineHQ & helpers
RUN dpkg --add-architecture i386 \
 && apt-get update \
 && apt-get install -y \
      wget \
      ca-certificates \
      gnupg2 \
      software-properties-common \
      cabextract \
      p7zip-full \
 && mkdir -pm755 /etc/apt/keyrings /tmp/runtime \
 && wget -O /etc/apt/keyrings/winehq.key \
      https://dl.winehq.org/wine-builds/winehq.key \
 && echo "deb [signed-by=/etc/apt/keyrings/winehq.key] \
      https://dl.winehq.org/wine-builds/ubuntu/ $(lsb_release -cs) main" \
      > /etc/apt/sources.list.d/winehq.list \
 && apt-get update \
 && apt-get install -y --install-recommends \
      winehq-stable \
      winbind \
      xvfb \
 && rm -rf /var/lib/apt/lists/*

# 2) Create non-root user
RUN groupadd wine \
 && useradd -m -s /bin/bash -g wine wine \
 && chown -R wine:wine /home/wine

USER wine
ENV WINEARCH=win64 \
    WINEPREFIX=/home/wine/.wine \
    DISPLAY=:0

# 3) Install MetaTrader 5 (Wine auto-creates prefix)
RUN wget -O /tmp/mt5setup.exe \
      "https://download.mql5.com/cdn/web/metaquotes.ltd/mt5/mt5setup.exe" \
 && xvfb-run --auto-servernum --server-args='-screen 0 1024x768x24' \
      wine /tmp/mt5setup.exe /quiet InstallAllUsers=1 PrependPath=1 \
 && rm /tmp/mt5setup.exe

# 4) Install Windows-Python 3.10 + pip under Wine
RUN wget -O /tmp/python-installer.exe \
      "https://www.python.org/ftp/python/3.10.0/python-3.10.0-amd64.exe" \
 && xvfb-run --auto-servernum --server-args='-screen 0 1024x768x24' \
      wine /tmp/python-installer.exe \
        /passive PrependPath=1 Include_pip=1 \
 && rm /tmp/python-installer.exe

# 5) Install MCP STDIO + MetaTrader5 wrapper into Wine’s Python
RUN xvfb-run --auto-servernum --server-args='-screen 0 1024x768x24' \
      wine pip install --no-cache-dir metatrader-mcp-server MetaTrader5

# 6) Copy entrypoint
USER root
COPY entrypoint_stdio.sh /usr/local/bin/entrypoint_stdio.sh
RUN chmod +x /usr/local/bin/entrypoint_stdio.sh

# 7) Back to wine user & entrypoint
USER wine
ENTRYPOINT ["/usr/local/bin/entrypoint_stdio.sh"]