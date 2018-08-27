#/bin/sh
Bastion_IP=`grep bastion $1 | awk '{print $2}' | awk -F "=" '{print $2}'`
Hosts=( $(cat $1 | grep 'ansible_user_id=centos' | grep kuber | awk '{print $1}') )
IP=( $(cat $1 | grep 'ansible_user_id=centos' | grep kuber | awk '{print $2}' | awk -F "=" '{print $2}') )
lenth=${#IP[*]}
Auth=$2
kafkahost=( $(cat hosts_pro | grep kafka | grep -v ansible | grep -v '\[') )
kafkaIP=( $(cat $1 | grep kafka | grep ansible |  awk '{print $2}' | awk -F "=" '{print $2}') )
lenth1=${#kafkaIP[*]}

Load(){
echo "**************Load Average****************"
ssh -i $Auth -o ProxyCommand="ssh -W %h:%p -i $Auth centos@$Bastion_IP" centos@$1 uptime 1 2>/dev/null;
}

Pod(){
if [[ "$2" =~ "master1" ]];then
echo "**************Pods under admin****************"
ssh -i $Auth -o ProxyCommand="ssh -W %h:%p -i $Auth centos@$Bastion_IP" centos@$1 kubectl get pods -n admin | grep -vi running  
echo "**************Pods under kube-system****************"
ssh -i $Auth -o ProxyCommand="ssh -W %h:%p -i $Auth centos@$Bastion_IP" centos@$1 kubectl get pods -n kube-system | grep -vi running 
echo "**************Pods under kube-system****************"
ssh -i $Auth -o ProxyCommand="ssh -W %h:%p -i $Auth centos@$Bastion_IP" centos@$1 kubectl get pods | grep -vi running 
fi
}

IPTable(){
echo "**************IP tables check****************"
ssh -i $Auth -o ProxyCommand="ssh -W %h:%p -i $Auth centos@$Bastion_IP" centos@$1 sudo iptables -L | grep -i 'Chain OUTPUT'
}

CalIPT(){
echo "**************Cal IP tables list****************"
ssh -i $Auth -o ProxyCommand="ssh -W %h:%p -i $Auth centos@$Bastion_IP" centos@$1 sudo cat /etc/sysconfig/iptables | wc -l
}



SaveIPTable(){
echo "**************IP tables check****************"
ssh -i $Auth -o ProxyCommand="ssh -W %h:%p -i $Auth centos@$Bastion_IP" centos@$1 sudo service iptables save
}

LoginAWSDoc(){
echo "**************Login AWS Docker****************"
ssh -i $Auth -o ProxyCommand="ssh -W %h:%p -i $Auth centos@$Bastion_IP" centos@$1 sudo $(aws ecr get-login --no-include-email --region cn-north-1)
}

Kaf_Zoo_chk(){
echo "**************Check kafka service****************"
ssh -i $Auth -o ProxyCommand="ssh -W %h:%p -i $Auth centos@$Bastion_IP" centos@$1  systemctl status kafka.service | grep Active 
echo "**************Check zookeeper service****************"
ssh -i $Auth -o ProxyCommand="ssh -W %h:%p -i $Auth centos@$Bastion_IP" centos@$1  systemctl status zookeeper.service | grep Active 
}

for ((i=0; i<${lenth}; i++));
do
    echo "Health Check on ${Hosts[$i]}:";
    Load ${IP[$i]}
    Pod ${IP[$i]} ${Hosts[$i]}
#    IPTable ${IP[$i]}
#     SaveIPTable ${IP[$i]}
#     CalIPT ${IP[$i]}
#     LoginAWSDoc ${IP[$i]} 
done 
for ((i=0; i<${lenth1}; i++));
do
    echo "Health Check on ${kafkahost[$i]}:";
    Kaf_Zoo_chk ${kafkaIP[$i]} ${kafkahost[$i]}
done
