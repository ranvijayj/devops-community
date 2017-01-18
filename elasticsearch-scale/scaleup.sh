#!/bin/bash


NAME="elb-name"

AZ="ap-south-1a"
date_end=`date -u +"%Y-%m-%dT%H:%M:%SZ"`
#date --date "$date_end -10 min"
date_start=`date -u +"%Y-%m-%dT%H:%M:%SZ" --date "$date_end -5 min"`
original_cluster_nodes_count=$1


#######################################################ELB STEPS###########################################################


var=`/usr/local/bin/aws cloudwatch get-metric-statistics --namespace AWS/ELB --metric-name  Latency --start-time $date_start  --end-time $date_end  --period 60   --statistics Average --dimensions '[{"Name":"LoadBalancerName","Value":"'$NAME'"},{"Name":"AvailabilityZone","Value":"'$AZ'"}]' --unit Seconds | awk '{print $2}' `

{ echo "${var[*]}"; } > cat.txt
total=`awk '{ SUM += $1} END { print SUM }' cat.txt`
var2=$(echo "scale=2; ($total/5.0) *100 "|bc)

delay=${var2%.*}

#500 below means 5 seconds################

function scale_up ()
{
if [ $delay -ge 300 ]; then

###If condition is true, then increase node count by 2

        count=2
        /usr/local/bin/aws es describe-elasticsearch-domain-config --domain-name name > test123.txt
        instance_current_count=`cat test123.txt | awk '{print $3}'| awk 'NR==7'`
        instance_new_auto_count=`expr $count + $instance_current_count`

###Update cluster configuration#############

        /usr/local/bin/aws es update-elasticsearch-domain-config --elasticsearch-cluster-config "InstanceType=m4.large.elasticsearch,InstanceCount=$instance_new_auto_count" --domain-name name
fi
}
scale_up

