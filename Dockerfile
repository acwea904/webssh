FROM python:3.10-alpine

LABEL maintainer='<author>'
LABEL version='0.0.0-dev.0-build.0'

ADD . /code
WORKDIR /code

# 安装依赖并下载稳定版探针 (v0.20.5)
RUN \
  apk add --no-cache libc-dev libffi-dev gcc curl wget unzip && \
  pip install --no-cache-dir paramiko==3.0.0 tornado==6.2.0 && \
  ARCH=$(uname -m) && \
  if [ "$ARCH" = "x86_64" ]; then ARCH="amd64"; elif [ "$ARCH" = "aarch64" ]; then ARCH="arm64"; fi && \
  wget -t 2 -T 10 -O nezha-agent.zip https://github.com/nezhahq/agent/releases/download/v0.20.5/nezha-agent_linux_${ARCH}.zip && \
  unzip nezha-agent.zip && \
  mv nezha-agent /usr/bin/nezha-agent && \
  chmod +x /usr/bin/nezha-agent && \
  rm -f nezha-agent.zip && \
  apk del gcc libc-dev libffi-dev && \
  addgroup -S webssh && \
  adduser -Ss /bin/false -G webssh webssh && \
  chown -R webssh:webssh /code

EXPOSE 8888/tcp

USER root

# 设置哪吒探针需要的环境变量，这与你提供的脚本逻辑完全一致
ENV NZ_SERVER=agn.xinxi.pp.ua:443
ENV NZ_TLS=true
ENV NZ_CLIENT_SECRET=1FyZCXk9XGSarBQrCVE8WjyzXTfJFqH4

# 启动命令：
# 1. 启动探针：直接运行并从环境变量读取配置
# 2. 启动 WebSSH：注入 asyncio 补丁并降权运行
CMD /usr/bin/nezha-agent -s ${NZ_SERVER} -p ${NZ_CLIENT_SECRET} --tls > /dev/null 2>&1 & \
    su webssh -s /bin/sh -c "python3 -c 'import asyncio; asyncio.set_event_loop(asyncio.new_event_loop())'; python3 run.py --delay=10 --encoding=utf-8 --fbidhttp=False --maxconn=20 --policy=warning --redirect=False --timeout=10 --xsrf=False --xheaders --wpintvl=1"
