FROM python:3.10-alpine

LABEL maintainer='author'

ADD . /code
WORKDIR /code

# 1. 升级 paramiko 解决 Cryptography 警告
# 2. 增加持久化环境变量支持
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

# 建议在部署平台（如 Render）的环境变量设置中修改以下值，而不是死写在这里
ENV NZ_SERVER=agn.xinxi.pp.ua:443
ENV NZ_TLS=true
ENV NZ_CLIENT_SECRET=1FyZCXk9XGSarBQrCVE8WjyzXTfJFqH4

USER root

# 改进启动脚本：
# 使用 exec 模式并确保环境变量被正确读取
CMD ["/bin/sh", "-c", "/usr/bin/nezha-agent -s ${NZ_SERVER} -p ${NZ_CLIENT_SECRET} --tls --debug & su webssh -s /bin/sh -c \"python3 run.py --delay=10 --encoding=utf-8 --fbidhttp=False --maxconn=20 --policy=warning --redirect=False --timeout=10 --xsrf=False --xheaders --wpintvl=1\""]
