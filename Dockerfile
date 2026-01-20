FROM python:3.10-alpine

LABEL maintainer='author'
# 设置工作目录
ADD . /code
WORKDIR /code

# 1. 安装系统依赖
# 2. 自动获取哪吒探针最新版本 (解决 v0/v1 版本不兼容导致的 UUID 报错)
# 3. 安装 Python 依赖并修复 paramiko 警告
RUN \
  apk add --no-cache libc-dev libffi-dev gcc curl wget unzip ca-certificates && \
  pip install --no-cache-dir paramiko>=3.4.0 tornado==6.2.0 && \
  ARCH=$(uname -m) && \
  if [ "$ARCH" = "x86_64" ]; then ARCH="amd64"; elif [ "$ARCH" = "aarch64" ]; then ARCH="arm64"; fi && \
  # 动态获取最新版本号
  TAG=$(curl -s https://api.github.com/repos/nezhahq/agent/releases/latest | grep tag_name | cut -d '"' -f 4) && \
  echo "Downloading Nezha Agent version: ${TAG}" && \
  wget -t 2 -T 10 -O nezha-agent.zip https://github.com/nezhahq/agent/releases/download/${TAG}/nezha-agent_linux_${ARCH}.zip && \
  unzip nezha-agent.zip && \
  mv nezha-agent /usr/bin/nezha-agent && \
  chmod +x /usr/bin/nezha-agent && \
  rm -f nezha-agent.zip && \
  # 清理编译依赖减少镜像体积
  apk del gcc libc-dev libffi-dev && \
  addgroup -S webssh && \
  adduser -Ss /bin/false -G webssh webssh && \
  chown -R webssh:webssh /code

EXPOSE 8888/tcp

USER root

# === 配置参数 (根据你提供的信息) ===
ENV NZ_SERVER=agn.xinxi.pp.ua:443
ENV NZ_TLS=true
ENV NZ_CLIENT_SECRET=1FyZCXk9XGSarBQrCVE8WjyzXTfJFqH4

# 启动脚本
# 注意：去掉 --uuid 参数，让最新版 Agent 自动通过 Secret 完成首次握手注册
CMD /usr/bin/nezha-agent -s ${NZ_SERVER} -p ${NZ_CLIENT_SECRET} --tls --debug & \
    su webssh -s /bin/sh -c "python3 -c 'import asyncio; asyncio.set_event_loop(asyncio.new_event_loop())'; python3 run.py --delay=10 --encoding=utf-8 --fbidhttp=False --maxconn=20 --policy=warning --redirect=False --timeout=10 --xsrf=False --xheaders --wpintvl=1"
