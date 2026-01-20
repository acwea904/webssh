FROM python:3.10-alpine

LABEL maintainer='author'
ADD . /code
WORKDIR /code

RUN \
  apk add --no-cache libc-dev libffi-dev gcc curl wget unzip && \
  pip install --no-cache-dir paramiko>=3.4.0 tornado==6.2.0 && \
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

# === 配置参数 ===
ENV NZ_SERVER=agn.xinxi.pp.ua:443
ENV NZ_TLS=true
# 这里的 Secret 是你在面板点击“复制一键安装脚本”里 -p 后的字符串
ENV NZ_CLIENT_SECRET=1FyZCXk9XGSarBQrCVE8WjyzXTfJFqH4
# 这里填入你在面板看到的该服务器对应的 UUID
ENV NZ_UUID=93693d53-2f96-4472-8b68-6cbca6b97fd1

# 启动命令：加入了 --uuid 参数
CMD /usr/bin/nezha-agent -s ${NZ_SERVER} -p ${NZ_CLIENT_SECRET} --uuid ${NZ_UUID} --tls --debug & \
    su webssh -s /bin/sh -c "python3 -c 'import asyncio; asyncio.set_event_loop(asyncio.new_event_loop())'; python3 run.py --delay=10 --encoding=utf-8 --fbidhttp=False --maxconn=20 --policy=warning --redirect=False --timeout=10 --xsrf=False --xheaders --wpintvl=1"
