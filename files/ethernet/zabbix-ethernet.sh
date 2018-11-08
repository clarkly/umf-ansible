#!/bin/bash

#check bond0 ethernet status ,altering when ethernet down
#20181031
#zabbix config
#UserParameter=ethernet.lld[*],/bin/sh /usr/local/bin/zabbix-ethernet.sh list
#UserParameter=ethernet.get[*],/bin/sh /usr/local/bin/zabbix-ethernet.sh $1 $2



if [ ! -d /proc/net/bonding/ ];then
	exit
fi



arg(){
	echo -e "1. list\t"
        echo -e "2. #{ethernet}\tstatus"
        echo -e "3. #{ethernet}\tspeed"
}


ethernet_lld(){
#LLD ETHERNET
#cat /proc/net/bonding/bond*|awk -v p=arg -F : '{gsub(/Mbps/,"",$0)};/Slave Interface:/{name=$2};/MII Status:/{status=$2};/Speed:/{if(p=='lld')print name,status,$2}'
netarr=($(cat /proc/net/bonding/bond*|awk -F : '{gsub(/Mbps/,"",$0)};/Slave Interface:/{name=$2};/MII Status:/{status=$2};/Speed:/{ print name}'))
 length=${#netarr[@]}
printf "{\n"
printf  '\t'"\"data\":["
for ((i=0;i<$length;i++))
do

        printf '\n\t\t{'

        printf "\"{#NAME}\":\"${netarr[$i]}\"}"

        if [ $i -lt $[$length-1] ];then

                printf ','

        fi

done
printf  "\n\t]\n"
printf "}\n"
}

get(){
name=$2
cat /proc/net/bonding/bond*|awk -F : '{gsub(/Mbps/,"",$0)};/Slave Interface:/{name=$2};/MII Status:/{status=$2};/Speed:/{print name,status,$2}'|grep $1|awk -v status=$name '{if(status=="status") print $2;else if (status=="speed") print $3}'

}
if [[ $1 == "" || $1 == "--help" ]];then
	arg
elif [[ $1 == 'list'  ]]; then
	ethernet_lld
elif [[ $2=='status' ]] ;then
        get $1 $2
elif [[ $2 == 'speed' ]];then
	get $1 $2
else
	arg
fi

exit

