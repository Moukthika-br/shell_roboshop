#!/bin/bash

AMI_ID="ami-09c813fb71547fc4f"
SG_ID="sg-0f977c21cf9763319"
INSTANCES=("mongodb" "redis" "mysql" "rabbitmq" "catalogue" "user" "shipping" "payment" "dispatch" "frontend")
ZONE_ID="Z025072226A39JCBZP3HB"
DOMAIN_ID="moukthika.site"

for instance in ${INSTANCES[@]}
do 


   INSTANCE_ID=$( aws ec2 run-instances
    --image-id ami-09c813fb71547fc4f 
    --instance-type t2.micro
    --security-group-ids sg-0f977c21cf9763319
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name, Value=test}]" 
     --query "Reservations[0].Instances[0].PrivateIpAddress" 
    --output text)
    if [ $instance!="frontend" ]
    then 
    IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query "Reservations[0].Instances[0].PrivateIpAddress" --output text)
    else
     IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query "Reservations[0].Instances[0].PublicIpAddress" --output text)
        fi
            echo "$instance IP address: $IP"


done
