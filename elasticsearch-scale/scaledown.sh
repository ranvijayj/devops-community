
#!/bin/bash

#####################CHANGE ELB NAME#########################
NAME="ELB-name"
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

###########Value of delay == 500 means 5 seconds################

function scale_down ()
{
   if [ $delay -le 300 ]; then

############check current size of cluster###############
        /usr/local/bin/aws es describe-elasticsearch-domain-config --domain-name name  > test123.txt
        instance_current_count=`cat test123.txt | awk '{print $3}'| awk 'NR==7'`

        if [ $instance_current_count -eq $original_cluster_nodes_count ]; then

             echo "size okay"

        elif [ $instance_current_count -gt $original_cluster_nodes_count ]; then

       /usr/local/bin/aws es update-elasticsearch-domain-config --elasticsearch-cluster-config "InstanceType=m4.large.elasticsearch,InstanceCount=$original_cluster_nodes_count" --domain-name name

         echo "Things look okay now. Cluster Scaled down to $original_cluster_nodes_count"
        fi


   fi
}
scale_down
