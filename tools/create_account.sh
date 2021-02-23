#!/bin/bash
source /etc/profile

# ====================方法准备=========================
function check_ip_format() {
    local IP="$(cat)"
    if [[ "${IP}" =~ ^([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5]).([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5]).([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5]).([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])$ ]];then
        return 0
    else
        return 1
    fi
}

# ===================默认参数处理======================
# shellcheck disable=SC2006
default_password=`date +%s | sha256sum | base64 | head -c 16 ; echo`
default_useraccount="zhuiyi"
default_expires_days=3

# ====================参数处理=========================
while true
do
    read  -p "please input host ip: " HOSTIP
    echo "${HOSTIP}" | check_ip_format
    # shellcheck disable=SC2181
    if [ $? -eq 0 ];then
        break
    else
        echo "Ip addr format error, pleas input again"
    fi
done

read  -p "please input user name(default: ${default_useraccount}): " useraccount
useraccount=${useraccount:-${default_useraccount}}

read  -p "please input host userpassword(default: ${default_password}): " userpassword
userpassword=${userpassword:-${default_password}}

read  -p "please input the account expires times(default: ${default_expires_days} days): " expires
expires=${expires:-${default_expires_days}}


# =======================执行入口============================
sshpass -p Dl7mdkzbMLwe0FBu ssh -o StrictHostKeyChecking=no root@"${HOSTIP}" sh << EOF
#!/bin/bash
useraccount=${useraccount}
userpassword=${userpassword}
expires=${expires}
ip=${HOSTIP}

if [[ \`cat /etc/passwd | grep -v /sbin/nologin | cut -d : -f 1 | grep -w "\${useraccount}" | wc -l\` -ge 1 ]]; then
    echo "\${useraccount} account exist"
    chage -E \`date -d "-\${expires} day ago" -I\` \${useraccount} > /dev/null 2>&1 || exit 1
    echo "\${userpassword}" | passwd --stdin \${useraccount} && echo "set password success." || (echo "set password faild.";exit 1)
else
    useradd -e \`date -d "-\${expires} day ago" -I\` \${useraccount} || exit 1
    if [[ \$? -eq 0 ]]; then
        echo "useradd \${useraccount} account success ..."
        echo "\${userpassword}" | passwd --stdin \${useraccount} && echo "set password success." || echo "set password faild."
        chage -l \${useraccount}
    else
        echo "useradd \${useraccount} account failed ..."
        exit 2
    fi
fi

if [[ \`grep -ar "^\${useraccount}" /etc/sudoers\` ]]; then
   echo "\${useraccount} has sudo ..."
 else
   echo "\${useraccount}    ALL=(ALL)       ALL" >> /etc/sudoers && echo "add \${useraccount} sudoers success" || (echo "add \${useraccount} sudoers failed ..."; exit 1)
fi

# 结果输出
echo "==================================================="
echo "ip: \${ip}"
echo "username: \${useraccount}"
echo "userpassword: \${userpassword}"
echo "expires date: \`date -d "-\${expires} day ago" -I\`"
echo "==================================================="
EOF

date_now=`date +"%Y-%m-%y %H:%M:%S"`
user=`whoami`

mysql -h 172.16.30.7 -P 13306 -uroot -pDEVOPS123 log << EOF1
INSERT INTO \`log\`.\`create_user_log\` (\`ip\`, \`user_name\`, \`user_passwd\`, \`expires date\`,\`create_time\`, \`current_user\`) VALUES ("${HOSTIP}", "${useraccount}", "${userpassword}", "${date_now}", "${user}");
EOF1