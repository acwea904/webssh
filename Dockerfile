FROM python:3-alpine

LABEL maintainer='<author>'
LABEL version='0.0.0-dev.0-build.0'

ADD . /code
WORKDIR /code

# 安装依赖、下载哪吒探针并配置权限
RUN \
  apk add --no-cache libc-dev libffi-dev gcc curl wget && \
  pip install -r requirements.txt --no-cache-dir && \
  # 下载并安装哪吒探针 (针对 Alpine/Linux amd64)
  # 注意：这里直接下载二进制文件更稳定，避免在容器内运行复杂的交互式脚本
  wget -t 2 -T 10 -O nezha-agent.zip https://github.com/nezhahq/agent/releases/latest/download/nezha-agent_linux_amd64.zip && \
  unzip nezha-agent.zip && \
  mv nezha-agent /usr/bin/nezha-agent && \
  chmod +x /usr/bin/nezha-agent && \
  rm -f nezha-agent.zip && \
  # 清理环境
  apk del gcc libc-dev libffi-dev && \
  addgroup webssh && \
  adduser -Ss /bin/false -g webssh webssh && \
  chown -R webssh:webssh /code

EXPOSE 8888/tcp

# 切换回 root 以确保有权限启动探针（或者确保 webssh 用户有执行权限）
USER root

# 使用 sh 启动多个进程
# 环境变量已嵌入启动命令中
CMD /usr/bin/nezha-agent -s agn.xinxi.pp.ua:443 -p 1FyZCXk9XGSarBQrCVE8WjyzXTfJFqH4 --tls & \
    su webssh -s /bin/sh -c "python run.py --delay=10 --encoding=utf-8 --fbidhttp=False --maxconn=20 --origin=* --policy=warning --redirect=False --timeout=10 --debug --xsrf=False --xheaders --wpintvl=1"
