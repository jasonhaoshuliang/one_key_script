#!/bin/bash
# 该脚本用于无脑安装docker-compose

# TODO List
# 1: 修改为传参的形式

function help() {
    echo -e "\033[1;37m"
    echo -e "Usage:"
    echo -e "    bash $( basename "$0" ) install   <OPTIONS>  安装docker-compose"
    echo -e "    bash $( basename "$0" ) uninstall <OPTIONS>  卸载docker-compose"
    echo -e "    bash $( basename "$0" ) --help               查看帮助信息"
    exit 0
}

function install() {
  docker_compose_version='1.28.4'
  # 首先检查 是否已经安装
  type docker-compose >/dev/null 2>&1 && docker-compose --version | grep -o '1.28.4' >/dev/null 2>&1

  # shellcheck disable=SC2181
  if [[ $? -eq 0 ]]; then
    echo "docker-compose exist";
    exit 0;
  fi

  # 首先check有没有curl命令
  type curl >/dev/null 2>&1 || { echo >&2 "I require curl but it's not installed. Aborting."; exit 1; } && echo "Curl command exist"

  # 使用国内镜像下载
  curl -L https://get.daocloud.io/docker/compose/releases/download/${docker_compose_version}/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
  # shellcheck disable=SC2181
  if [[ $? -eq 0 ]]; then
    chmod +x /usr/local/bin/docker-compose
    ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
  else
    echo "install docker-compose:${docker_compose_version} failed"
    exit 1;
  fi
  docker-compose --version && echo "install docker-compose:${docker_compose_version} success"
}

function  uninstall() {
  # 首先检查是否已经安装
  type docker-compose >/dev/null 2>&1 && docker-compose --version >/dev/null 2>&1
  # shellcheck disable=SC2181
  if [[ $? -ne 0 ]]; then
    echo "docker-compose not exist, docker-compose can not uninstall";
    exit 1;
  fi

  # 卸载docker-compose
  # shellcheck disable=SC2006
  # shellcheck disable=SC2230
  dir=`which docker-compose`
  # shellcheck disable=SC2181
  if [[ $? -ne 0 ]]; then
    echo "which docker-compose failed"; exit 1;
  fi

  # shellcheck disable=SC2015
  rm -f "${dir}" && echo "clean bin files success" || (echo "clean bin files failed"; exit 1;)
  # shellcheck disable=SC2015
  rm -f /usr/bin/docker-compose && echo "clean soft link success" || (echo "clean soft link failed"; exit 1;)

  docker-compose --version >/dev/null 2>&1 || echo "uninstall docker-compose:${docker_compose_version} success"
}

case $1 in
    install)
      install "${@:2}"
    ;;
    uninstall)
      uninstall "${@:2}"
    ;;
    ""|--help)
      help
    ;;
    *)
      help
    ;;
esac