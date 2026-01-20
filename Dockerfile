FROM python:3.10-alpine

LABEL maintainer='<author>'
LABEL version='0.0.0-dev.0-build.0'

ADD . /code
WORKDIR /code

RUN \
  apk add --no-cache libc-dev libffi-dev gcc curl wget unzip && \
  pip install --no-cache-dir paramiko==3.0.0 tornado==6.2.0 && \
  # 使用 v0.20.5 稳定版
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

# 核心修改：重新加入 --tls，这是 443 端口必须的
# 如果依然不行，请确认你的面板是否开启了 Cloudflare 的 gRPC 支持
CMD /usr/bin/nezha-agent -s agn.xinxi.pp.ua:443 -p 1FyZCXk9XGSarBQrCVE8WjyzXTfJFqH4 --tls --debug & \
    su webssh -s /bin/sh -c "python3 -c 'import asyncio; asyncio.set_event_loop(asyncio.new_event_loop())'; python3 run.py --delay=10 --encoding=utf-8 --fbidhttp=False --maxconn=20 --policy=warning --redirect=False --timeout=10 --xsrf=False --xheaders --wpintvl=1 --debug"
