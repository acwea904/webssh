FROM python:3.10-alpine

LABEL maintainer='<author>'
LABEL version='0.0.0-dev.0-build.0'

ADD . /code
WORKDIR /code

# 安装系统依赖、Python依赖
RUN \
  apk add --no-cache libc-dev libffi-dev gcc curl wget unzip && \
  # 固定 Tornado 和 Paramiko 版本以保证稳定性
  pip install --no-cache-dir paramiko==3.0.0 tornado==6.2.0 && \
  # 自动识别架构下载哪吒探针 (支持 amd64 和 arm64)
  ARCH=$(uname -m) && \
  if [ "$ARCH" = "x86_64" ]; then ARCH="amd64"; elif [ "$ARCH" = "aarch64" ]; then ARCH="arm64"; fi && \
  wget -t 2 -T 10 -O nezha-agent.zip https://github.com/nezhahq/agent/releases/latest/download/nezha-agent_linux_${ARCH}.zip && \
  unzip nezha-agent.zip && \
  mv nezha-agent /usr/bin/nezha-agent && \
  chmod +x /usr/bin/nezha-agent && \
  rm -f nezha-agent.zip && \
  # 清理编译依赖并创建专用用户
  apk del gcc libc-dev libffi-dev && \
  addgroup -S webssh && \
  adduser -Ss /bin/false -G webssh webssh && \
  chown -R webssh:webssh /code

EXPOSE 8888/tcp

# 使用 Root 启动，确保探针有权限获取系统信息
USER root

# 启动命令说明：
# 1. 哪吒探针：使用 service run 模式，开启 --debug，并且【移除】了 > /dev/null 以便查看报错
# 2. WebSSH：使用 su 切换用户，并注入 asyncio 补丁防止 Python 3.10+ 报错
CMD /usr/bin/nezha-agent service run --server agn.xinxi.pp.ua:443 --password 1FyZCXk9XGSarBQrCVE8WjyzXTfJFqH4 --tls --debug & \
    su webssh -s /bin/sh -c "python3 -c 'import asyncio; asyncio.set_event_loop(asyncio.new_event_loop())'; python3 run.py --delay=10 --encoding=utf-8 --fbidhttp=False --maxconn=20 --policy=warning --redirect=False --timeout=10 --xsrf=False --xheaders --wpintvl=1 --debug"
