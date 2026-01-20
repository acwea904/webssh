FROM python:3.10-alpine

LABEL maintainer='<author>'
LABEL version='0.0.0-dev.0-build.0'

ADD . /code
WORKDIR /code

# 安装依赖
RUN \
  apk add --no-cache libc-dev libffi-dev gcc curl wget unzip && \
  pip install --no-cache-dir paramiko==3.0.0 tornado==6.2.0 && \
  # ----------------------------------------------------------------
  # 核心修改：锁定使用 v0.20.5 版本，避免最新版参数不兼容的问题
  # ----------------------------------------------------------------
  ARCH=$(uname -m) && \
  if [ "$ARCH" = "x86_64" ]; then ARCH="amd64"; elif [ "$ARCH" = "aarch64" ]; then ARCH="arm64"; fi && \
  wget -t 2 -T 10 -O nezha-agent.zip https://github.com/nezhahq/agent/releases/download/v0.20.5/nezha-agent_linux_${ARCH}.zip && \
  unzip nezha-agent.zip && \
  # v0.20.5 解压后直接是二进制文件，移动到 bin 目录
  mv nezha-agent /usr/bin/nezha-agent && \
  chmod +x /usr/bin/nezha-agent && \
  rm -f nezha-agent.zip && \
  # 清理环境
  apk del gcc libc-dev libffi-dev && \
  addgroup -S webssh && \
  adduser -Ss /bin/false -G webssh webssh && \
  chown -R webssh:webssh /code

EXPOSE 8888/tcp

USER root

# 启动命令：
# 1. 哪吒探针 (v0.20.5)：恢复使用 -s -p 参数，移除不支持的 service run
# 2. WebSSH：保持之前的 asyncio 修复补丁
CMD /usr/bin/nezha-agent -s agn.xinxi.pp.ua:443 -p 1FyZCXk9XGSarBQrCVE8WjyzXTfJFqH4 --tls > /dev/null 2>&1 & \
    su webssh -s /bin/sh -c "python3 -c 'import asyncio; asyncio.set_event_loop(asyncio.new_event_loop())'; python3 run.py --delay=10 --encoding=utf-8 --fbidhttp=False --maxconn=20 --policy=warning --redirect=False --timeout=10 --xsrf=False --xheaders --wpintvl=1 --debug"
