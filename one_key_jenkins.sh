#!/bin/bash
# Author: hao.shuliang
# E-mail: shulianghao@163.com
# Content: One key install jenkins

## ----------------------------------------------------------
export PATH=/sbin:/usr/sbin:/usr/local/sbin:/usr/local/bin:/usr/bin:/bin
export TERM="xterm-256color"
export WORKDIR=$( cd ` dirname $0 ` && pwd )
cd "$WORKDIR" || exit 1
## ----------------------------------------------------------

info() {
    echo "Info: $@"
}

warn() {
    echo "Warning: $@"
}

error() {
    echo "Error: $@"
}

err_exit() {
    echo "Error: $@"
    exit 1
}

## ----------------------------------------------------------
# 基础配置


## ----------------------------------------------------------

OPT="" # 安装方式


select_install_way() {
	# 选择安装方式
	while true;
	do
		echo  "The ways of installing jenkins shown below: "
		echo  "   1: docker (You have to make sure your os have installed docker.)"
		echo  "   2: virtual machine "
		read  -p "Which you want ? pls input 1 or 2: " OPT
		if [[ ${OPT} -eq 1 ]];then
		    info "Now you will install jenkins with way of docker."
		    docker_install
			break
		elif [[ ${OPT} -eq 2 ]];then
		    info "Now you will install jenkins with way of virtual machine."
		    vm_install
			break
		else
			error "Sorry, you have input a wrong option. "
		fi
	done
}


is_root() {
	if [[ `id -u` -eq 0 ]]; then
		info "Check you are root."
	else
		err_exit "You are not root. exiting... "
	fi
}

check_dir() {
    # 判断有没有目录，有就忽略，没有就创建
    dir=$1
    if [[ ! -d  ${dir} ]]; then
        mkdir -p ${dir} && info "Creating workspace: ${dir} success." || err_exit "Creating workspace: ${dir}  failed."
    fi
}

install_docker() {
    # 安装docker
    yum install -y yum-utils  device-mapper-persistent-data lvm2
    yum-config-manager  --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    yum install docker-ce docker-ce-cli containerd.io -y
    docker_v=`yum list docker-ce --showduplicates | sort -r | grep "^docker.*" | head -n 1 | egrep -o "[0-9]*\.[0-9]*\.[0-9]*"`
    yum install docker-ce-"${docker_v}" docker-ce-cli-"${docker_v}" containerd.io
    sleep 2
    systemctl start docker
    sleep 5
    docker run hello-world && info "Install docker success."

}

install_com() {
    # 安装组件的函数
    com_name=$1
    read  -p "Are you will install ${com_name}, yes or no(default yes):" yes
    yes=${yes:-yes}
    if [[ "${yes}"x = "yes"x ]];then
        echo ""
    else
        info "Exit install $}=${com_name}"
        exit 0
    fi

    if [[ "${com_name}"x = "maven"x ]]; then
        mvn --version > /dev/null 2>&1 && (info "maven exist"; exit 0) || info "maven does not exist."
        # 首先下载maven
        read  -p "Input maven workspace(default /app/maven):" dir_maven_dir
        dir_maven_dir=${dir_maven_dir:-/app/maven}
        check_dir ${dir_maven_dir}
        wget https://mirrors.tuna.tsinghua.edu.cn/apache/maven/maven-3/3.6.3/binaries/apache-maven-3.6.3-bin.tar.gz -P ${dir_maven_dir} > /dev/null >&1 && info "Download maven success" || err_exit "Download maven failed"
        tar -zxf "${dir_maven_dir}/apache-maven-3.6.3-bin.tar.gz" --strip-components 1 -C ${dir_maven_dir} && info "Unzip maven success" || err_exit "Unzip maven failed"
        echo 'export M2_HOME='${dir_maven_dir}'' >> /etc/profile || err_exit "Writ failed"
        echo 'export PATH=$PATH:$M2_HOME/bin' >> /etc/profile || err_exit "Writ failed"
        source /etc/profile || err_exit "Load env variable failed."
        mvn --version && info "install maven success" || err_exit "install maven failed."
        rm -f "${dir_maven_dir}/apache-maven-3.6.3-bin.tar.gz" && info "Delete maven source file success."
    elif [[ "${com_name}"x = "jdk"x ]]; then
        java -version > /dev/null 2>&1 && (info "jdk exist"; exit 0) || info "jdk does not exist."
        read  -p "Input jdk workspace(default /app/jdk):" dir_jdk_dir
        dir_jdk_dir=${dir_jdk_dir:-/app/jdk}
        check_dir ${dir_jdk_dir}
        wget https://repo.huaweicloud.com/java/jdk/13+33/jdk-13_linux-x64_bin.tar.gz -P ${dir_jdk_dir} > /dev/null >&1 && info "Download jdk success" || err_exit "Download jdk failed"
        tar -zxf ${dir_jdk_dir}/jdk-13_linux-x64_bin.tar.gz --strip-components 1 -C ${dir_jdk_dir} && info "Unzip jdk success" || err_exit "Unzip jdk failed"
        echo 'export JAVA_HOME='${dir_jdk_dir}''  >> /etc/profile || err_exit "Writ failed"
        echo 'export CLASSPATH=.:${JAVA_HOME}/jre/lib/rt.jar:${JAVA_HOME}/lib/dt.jar:${JAVA_HOME}/lib/tools.jar'  >> /etc/profile || err_exit "Writ failed"
        echo 'export PATH=$PATH:${JAVA_HOME}/bin'  >> /etc/profile || err_exit "Writ failed"
        source /etc/profile || err_exit "Load env variable failed."
        java -version && info "install jdk success" || err_exit "install jdk failed."
        rm -f "${dir_jdk_dir}/jdk-13_linux-x64_bin.tar.gz" && info "Delete jdk source file success."
    elif [[ "${com_name}"x = "tomcat"x ]]; then
        read  -p "Input tomcat workspace(default /app/tomcat):" dir_tomcat_dir
        dir_tomcat_dir=${dir_tomcat_dir:-/app/tomcat}
        check_dir ${dir_tomcat_dir}
        wget https://mirrors.tuna.tsinghua.edu.cn/apache/tomcat/tomcat-8/v8.5.54/bin/apache-tomcat-8.5.54.tar.gz -P ${dir_tomcat_dir} > /dev/null >&1 && info "Download tomcat success" || err_exit "Download tomcat  failed"
        tar -zxf ${dir_tomcat_dir}/apache-tomcat-8.5.54.tar.gz --strip-components 1 -C ${dir_tomcat_dir} && info "Unzip tomcat success" || err_exit "Unzip tomcat failed"
        wget https://mirrors.huaweicloud.com/jenkins/war/2.232/jenkins.war -P"${dir_tomcat_dir}/webapps"  > /dev/null >&1 && info "Download jenkins success" || err_exit "Download jenkins  failed"
        rm -f "${dir_tomcat_dir}/apache-tomcat-8.5.54.tar.gz" && info "Delete tomcat source file success."
        bash "${dir_tomcat_dir}/bin/startup.sh" && echo "start jenkins success." || echo "start jenkins failed."
        echo "The jenkins url: 127.0.0.1:8080/jenkins"
    else
        err_exit "Wrong, exiting..."
    fi

}

vm_install() {
    echo "Install jenkins with way of vm."
    source /etc/profile
    # 首先判断是否有java虚拟机
    install_com "jdk"
    install_com "maven"
    install_com "tomcat"
}


docker_install() {
    # 首先判断有没有docker
    docker --version > /dev/null 2>&1
    if [[ $? -eq 0 ]];then
        info "You have no docker on this host."
    else
        install_docker
    fi

    read  -p "Jenkins port (default 80): " jenkins_port
    jenkins_port=${jenkins_port:-80}
    read  -p "Jenkins JNLP port (default 50000):" jenkins_jnlp_port
    jenkins_jnlp_port=${jenkins_jnlp_port:-50000}
    # 下面是创建jenkins的目录
    while true;
    do
        read -p "Jenkins workspace(default /app/jenkins): " jenkins_work_dir
        jenkins_work_dir=${jenkins_work_dir:-/app/jenkins}
        if [[ ! -d  ${jenkins_work_dir} ]]; then
            info "The dir: ${jenkins_work_dir} does not exits. System will create ${jenkins_work_dir}"
            mkdir -p "${jenkins_work_dir}" || err_exit "Create ${jenkins_work_dir} failed" && info "Create ${jenkins_work_dir} success."
            chown -R 1000:1000 ${jenkins_work_dir} && info "Permission added successfully" || error "Permission added failed"
            if [[ $? -eq 0 ]]; then
                break;
            fi
        else
            num=`ls -A "${jenkins_work_dir}" | wc -w`
            if [[ ${num} -gt 0 ]]; then
               info "The dir of ${jenkins_work_dir} is not empty, please input again."
               continue
            fi
            chown -R 1000:1000 ${jenkins_work_dir} && info "Permission added successfully" || error "Permission added failed"
            info "The dir ${jenkins_work_dir} exists." && break
        fi
    done

    # 查看名字是否重复
    docker ps -a --format "{{.Names}}" | grep -w jenkins
    if [[ $? -eq 0 ]]; then
        jenkins_container_name="jenkins_`tr -cd '[:alnum:]' </dev/urandom | head -c 6`"
    else
        jenkins_container_name="jenkins"
    fi

     # 展示：
    echo "The jenkins config is showed below:"
    echo "    1 Access port: ${jenkins_port}"
    echo "    2 JNLP port: ${jenkins_jnlp_port}"
    echo "    3 Work_dir: ${jenkins_work_dir}"
    echo "    4 Container_name: ${jenkins_container_name}"
    read -p "Please confirm the information above, yes or no: " confirm
    if [[ "${confirm}"x = "yes"x ]]; then
        echo ""
    elif [[ "${confirm}"x = "no"x ]]; then
        info "The script exiting now."
        exit 0
    else
        err_exit "Input wrong."
    fi

    cmd="docker run --rm -d -p ${jenkins_port}:8080 -p ${jenkins_jnlp_port}:50000 -v '${jenkins_work_dir}':/var/jenkins_home -v /etc/localtime:/etc/localtime --name '${jenkins_container_name}' jenkins:2.60.3"
    info "[Command]: ${cmd}"
    if `eval echo "${cmd}"`; then
        info "Jenkins docker start success."
        info "Url is 127.0.0.1:${jenkins_port}"
        loop=0
        while true; do
            if [[ -f "${jenkins_work_dir}/secrets/initialAdminPassword" ]]; then
                admin_password=`cat ${jenkins_work_dir}/secrets/initialAdminPassword`
                info "The password of admin: ${admin_password}" && break
            else
                sleep 1
            fi
            ((loop++))
            if [[ "${loop}" -gt 20 ]]; then
                if [[ ! -n ${admin_password} ]]; then
                    error "Can not get admin password."
                fi
                break
            fi
        done
    else
        error "Jenkins docker start failed."
    fi
}

basic_check() {
    wget --help > /dev/null 2>&1 || yum install wget -y && info "install wget success."
}

# 判断是否为root
is_root
# 基础检查
basic_check
# 首先选择安装方式
select_install_way
