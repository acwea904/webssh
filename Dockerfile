FROM python:3.10-alpine

LABEL maintainer='author'
ADD . /code
WORKDIR /code

# 1. 安装系统依赖
# 2. 动态获取最新版哪吒探针 (v1.x+)
RUN \
  apk add --no-cache libc-dev libffi-dev gcc curl wget unzip ca-certificates && \
  pip install --no-cache-dir paramiko>=3.4.0 tornado==6.2.0 && \
  ARCH=$(uname -m) && \
  if [ "$ARCH" = "x86_64" ]; then ARCH="amd64"; elif [ "$ARCH" = "aarch64" ]; then ARCH="arm64"; fi && \
  # 获取最新版本标签并下载
  TAG=$(curl -s https://api.github.com/repos/nezhahq/agent/releases/latest | grep tag_name | cut -d '"' -f 4) && \
  wget -t 2 -T 10 -O nezha-agent.zip https://github.com/nezhahq/agent/releases/download/${TAG}/nezha-agent_linux_${ARCH}.zip && \
  unzip nezha-agent.zip && \
  mv nezha-agent /usr/bin/nezha-agent && \
  chmod +x /usr/bin/nezha-agent && \
  rm -f nezha-agent.zip && \
  # 清理缓存
  apk del gcc libc-dev libffi-dev && \
  addgroup -S webssh && \
  adduser -Ss /bin/false -G webssh webssh && \
  chown -R webssh:webssh /code

EXPOSE 8888/tcp

USER root

# === 配置参数 ===
# 这里的参数根据你提供的最新信息填写
ENV NZ_SERVER=agn.xinxi.pp.ua:443
ENV NZ_TLS=true
ENV NZ_CLIENT_SECRET=1FyZCXk9XGSarBQrCVE8WjyzXTfJFqH4
ENV NZ_UUID=93693d53-2f96-4472-8b68-6cbca6b97fd1

# 启动命令：
# 注意：v1.x 版本使用 --server 和 --password
CMD /usr/bin/nezha-agent --server ${NZ_SERVER} --password ${NZ_CLIENT_SECRET} --uuid ${NZ_UUID} --tls & \
    su webssh -s /bin/sh -c "python3 -c 'import asyncio; asyncio.set_event_loop(asyncio.new_event_loop())'; python3 run.py --delay=10 --encoding=utf-8 --fbidhttp=False --maxconn=20 --policy=warning --redirect=False --timeout=10 --xsrf=False --xheaders --wpintvl=1"
