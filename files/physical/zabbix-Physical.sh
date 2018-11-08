#!/bin/bash

#DELL MONITOR
# yum install srvadmin
#ln -s /opt/dell/srvadmin/sbin/racadm  /usr/sbin/racadm
#15 * * * * /usr/sbin/racadm getsensorinfo >/tmp/dell.log 2>/dev/null && /usr/sbin/racadm storage get pdisks -o >>/tmp/dell.log 2>/dev/null

#INSPUR MONITOR
#yum install ipmitool
#15 * * * * /usr/bin/ipmitool sdr elist >/tmp/inspur.log 2>/dev/null

#ZABBIX AGENT CONFIG
#/etc/zabbix/zabbix_agentd.d/zabbix-Physical.conf
#UserParameter=Physical-discovery[*],/bin/sh /usr/local/bin/zabbix-Physical.sh --d $1
#UserParameter=Physical-get[*],/bin/sh /usr/local/bin/zabbix-Physical.sh --get $1 $2

#ZABBIX SCRIPT PATH
#/usr/local/bin/zabbix-Physical.sh






type=$(dmidecode -t 1|grep Manufacturer|awk -F : '{if($2~/Dell/) print "dell";else if ($2~/Inspur/) print "Inspur" }')

dell_lld(){
        OLD_IFS="$IFS"
        IFS=","
        if [[ $1 =~ "memory" ]];then
		dell_arry=(`cat /tmp/dell.log|grep ^DIMM|grep -v  "Absent"|awk -F  "  "  '{gsub(/ /,".",$1)}{printf $1","}'`)
	fi
        if [[ $1 =~ "disk" ]];then
        OLD_IFS="$IFS"
        IFS=","
        dell_arry=(`grep "Disk.Bay.0:Enclosure" /tmp/dell.log -A 200000|grep -w "Name\|Status"|awk  '{if(NR%2!=0)ORS=" ";else ORS="\n";{gsub(/=/,"",$0)} print $0}'|awk -F " " '{gsub(/ +/," ",$0)}{gsub(/:/,".",$NF)}{printf "Physical.Disk."$NF"," }'`)
       fi
       if [[ $1 =~ "fan" ]];then
         dell_arry=(`cat /tmp/dell.log |grep 'Fan[0-9]' |awk -F  "  "  '{gsub(/ /,".",$1)}{printf $1","}'`)
       fi
       if [[ $1 =~ "psu" ]];then
         dell_arry=(`cat /tmp/dell.log |grep 'PS[0-9] Status' |awk -F  "  "  '{gsub(/ /,".",$1)}{printf $1","}'`)
       fi
       if [[ $1 =~ "cpu" ]];then
         dell_arry=(`cat /tmp/dell.log |grep 'CPU[0-9] Status' |awk -F  "  "  '{gsub(/ /,".",$1)}{printf $1","}'`)
       fi
 length=${#dell_arry[@]}
printf "{\n"
printf  '\t'"\"data\":["
for ((i=0;i<$length;i++))
do

        printf '\n\t\t{'

        printf "\"{#NAME}\":\"${dell_arry[$i]}\"}"

        if [ $i -lt $[$length-1] ];then

                printf ','

        fi

done
printf  "\n\t]\n"
printf "}\n"

}


get_dell(){
             if [[ $1 =~ "DIMM" && $2 == "memory" ]];then
               cat /tmp/dell.log|grep  -w "$1" |awk '{gsub(/ +/," ",$0)}{if($3~/Ok/) print "OK";else print "ERROR"}'
             fi
             if [[ $1 =~ "CPU" && $2 == "cpu" ]];then
              cat /tmp/dell.log |grep -w "$1" |awk '{gsub(/ +/," ",$0)}{if($3~/Ok/) print "OK";else print "ERROR"}'
            fi
            if [[ $1 =~ "Fan" && $2 == "fan" ]];then
              cat /tmp/dell.log |grep -w "$1" |awk '{gsub(/ +/," ",$0)}{if($4~/Ok/) print "OK";else print "ERROR"}'
            fi
            if [[ $1 =~ "PS" && $2 == "psu" ]];then
              cat /tmp/dell.log |grep -w "$1" |awk '{gsub(/ +/," ",$0)}{if($3~/Present/) print "OK";else print "ERROR"}'
            fi
            if [[ $1 =~ "Physical" && $2 == "disk" ]];then
grep "Disk.Bay.0:Enclosure" /tmp/dell.log -A 200000|grep -w "Name\|Status"|awk  '{if(NR%2!=0)ORS=" ";else ORS="\n";{gsub(/=/,"",$0);gsub(/ +/," ",$0)} print $0}'|grep -w "$1"| awk '{if($2~/Ok/) print "OK"; else print "ERROR"}'
            fi
}

inspur_lld(){
         if [[ $1 =~ "memory" ]];then
         inspur_arry=(`grep  ^MEM_ /tmp/inspur.log|awk -F \| '{if($NF!=" ") print $1}'`)
         fi
         if [[ $1 =~ "disk" ]];then
         inspur_arry=(`grep  -E   "HDD[0-9]{1,3}_Status"  /tmp/inspur.log|awk -F \| '{if($NF!=" ") print $1}'`)
         fi
         if [[ $1 =~ "fan" ]];then
         inspur_arry=(`grep FAN_ /tmp/inspur.log|grep -v "No Reading" |awk -F \| '{if($NF!=" ") print $1}'`)
         fi
         if [[ $1 =~ "psu" ]];then
         inspur_arry=(`grep PSU._Supply /tmp/inspur.log |awk -F \| '{if($NF!=" ") print $1}'`)
         fi
         if [[ $1 =~ "cpu" ]];then
         inspur_arry=(`grep -E "CPU[0-9]{1,3}_Status" /tmp/inspur.log |awk -F \| '{if($NF!=" ") print $1}'`)
         fi
        length=${#inspur_arry[@]}
	printf "{\n"
	printf  '\t'"\"data\":["
	for ((i=0;i<$length;i++))
		do

        		printf '\n\t\t{'

        		printf "\"{#NAME}\":\"${inspur_arry[$i]}\"}"

        if [ $i -lt $[$length-1] ];then

                printf ','

        fi

	done
	printf  "\n\t]\n"
	printf "}\n"
}

get_inspur(){
	if [[ $1 =~ "MEM"  && $2 == "memory" ]];then
                grep -E "$1" /tmp/inspur.log|awk -F \| '{gsub(/^ *| *$/,"",$NF)}{if($NF=="Presence Detected") print "OK";else print "ERROR"}'
        fi
        if [[ $1 =~ "FAN" && $2 == "fan" ]];then
               grep -E "$1" /tmp/inspur.log|awk -F \| '{if($3~/ok/) print "OK";else print "ERROR"}'
        fi
        if [[ $1 =~ "PSU" && $2 == "psu" ]];then
               grep -E "$1" /tmp/inspur.log|awk -F \| '{gsub(/^ *| *$/,"",$NF)}{if($NF=="Presence detected") print "OK";else print "ERROR"}'
        fi
        if [[ $1 =~ "CPU" && $2 == "cpu" ]];then
               grep -E "$1" /tmp/inspur.log|awk -F \| '{gsub(/^ *| *$/,"",$NF)}{if($NF=="Presence detected") print "OK";else print "ERROR"}'
        fi
        if [[ $1 =~ "HDD" && $2 == "disk" ]];then
             grep  -E  "$1"  /tmp/inspur.log|awk -F \| '{gsub(/^ *| *$/,"",$NF)}{if($NF=="Drive Present") print "OK";else print "ERROR"}'
        fi
}





if [ "$type"x = "dell"x ];then
         case "$1" in
                 (--discovery|--d)
                        dell_lld $2
                        ;;
                 (--get|-g)
                        get_dell $2 $3
        esac

elif [ "$type"x = "Inspur"x ];then
        case  "$1"  in
                (--discovery|--d)
                       inspur_lld $2
                         ;;
                (--get|-g)
                       get_inspur $2 $3
        esac
fi

exit
