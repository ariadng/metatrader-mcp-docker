# MetaTrader 5 + MCP (STDIO) — Ubuntu 24.04
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive \
    XDG_RUNTIME_DIR=/tmp/runtime \
    DISPLAY=:0

# -- 1. system packages -------------------------------------------------
RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates wget gnupg2 software-properties-common \
        cabextract p7zip-full xvfb winbind winetricks && \
    mkdir -p /etc/apt/keyrings && \
    wget -qO /etc/apt/keyrings/winehq.key https://dl.winehq.org/wine-builds/winehq.key && \
    echo "deb [signed-by=/etc/apt/keyrings/winehq.key] https://dl.winehq.org/wine-builds/ubuntu/ $(lsb_release -cs) main" \
        > /etc/apt/sources.list.d/winehq.list && \
    apt-get update && \
    apt-get install -y --install-recommends winehq-stable && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /tmp/runtime

# -- 2. non-root Wine user ----------------------------------------------
RUN groupadd -r wine && useradd -m -s /bin/bash -g wine wine
USER wine
ENV WINEARCH=win64 WINEPREFIX=/home/wine/.wine

# -- 3. core fonts (prevents kernel32 timeout) ---------------------------
RUN xvfb-run -a winetricks -q corefonts

# -- 4. install MT5 from local installer --------------------------------
COPY mt5setup.exe /tmp/mt5setup.exe
RUN xvfb-run -a wine /tmp/mt5setup.exe /quiet InstallAllUsers=1 PrependPath=1 && \
    rm /tmp/mt5setup.exe

# -- 5. Windows Python 3.10 + pip ---------------------------------------
RUN wget -qO /tmp/py.exe https://www.python.org/ftp/python/3.10.0/python-3.10.0-amd64.exe && \
    xvfb-run -a wine /tmp/py.exe /passive PrependPath=1 Include_pip=1 && \
    rm /tmp/py.exe

# -- 6. MCP server + MetaTrader5 wrapper --------------------------------
RUN xvfb-run -a wine pip install --no-cache-dir metatrader-mcp-server MetaTrader5

# -- 7. entrypoint -------------------------------------------------------
USER root
COPY entrypoint_stdio.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint_stdio.sh
USER wine
ENTRYPOINT ["/usr/local/bin/entrypoint_stdio.sh"]