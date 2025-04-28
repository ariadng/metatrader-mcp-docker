# Dockerfile: MetaTrader 5 + MCP Server (Ubuntu 24.04)
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Install system packages: Wine (from WineHQ), Xvfb, winbind, Python3, pip
RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get install -y wget gnupg2 software-properties-common && \
    mkdir -pm755 /etc/apt/keyrings && \
    wget -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key && \
    echo "deb [signed-by=/etc/apt/keyrings/winehq-archive.key] https://dl.winehq.org/wine-builds/ubuntu/ $(lsb_release -cs) main" > /etc/apt/sources.list.d/winehq.list && \
    apt-get update && \
    apt-get install -y --install-recommends winehq-stable xvfb winbind python3 python3-pip && \
    rm -rf /var/lib/apt/lists/*

# Install MetaTrader MCP Server Python package
RUN pip3 install --no-cache-dir metatrader-mcp-server

# Create a non-root 'wine' user
RUN groupadd -g 1000 wine && \
    useradd -m -s /bin/bash -u 1000 -g wine wine && \
    mkdir -p /home/wine/.wine && chown -R wine:wine /home/wine

# Switch to 'wine' user and set up Wine environment
USER wine
ENV WINEARCH=win64 WINEPREFIX=/home/wine/.wine

# Initialize Wine and install MetaTrader 5 (silent mode)
RUN xvfb-run --auto-servernum --server-args='-screen 0 1024x768x24' winecfg && \
    wget -O /tmp/mt5setup.exe "https://download.mql5.com/cdn/web/metaquotes.ltd/mt5/mt5setup.exe" && \
    xvfb-run --auto-servernum --server-args='-screen 0 1024x768x24' \
    wine /tmp/mt5setup.exe /quiet InstallAllUsers=1 PrependPath=1 && \
    rm /tmp/mt5setup.exe

# Switch back to root to add entrypoint script
USER root
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Use the entrypoint script and default to non-root user
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
USER wine
