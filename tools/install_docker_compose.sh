#!/bin/bash
# 该脚本用于无脑安装docker-compose

# TODO List
# 1: 修改为传参的形式

docker_compose_version='1.28.4'
# 首先check有没有curl命令
type curl >/dev/null 2>&1 || { echo >&2 "I require curl but it's not installed. Aborting."; exit 1; } && echo "Curl command exist"

# 使用国内镜像下载
curl -L https://get.daocloud.io/docker/compose/releases/download/${docker_compose_version}/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose

if [[ $? -eq 0 ]]; then
  sudo chmod +x /usr/local/bin/docker-compose
  sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
else
  echo "install docker-compose(version: ${docker_compose_version}) failed"
fi

