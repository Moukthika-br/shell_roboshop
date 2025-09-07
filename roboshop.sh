#!/bin/bash

AMI_ID="ami-09c813fb71547fc4f"
SG_ID="sg-0f977c21cf9763319"
INSTANCES=("mongodb" "redis" "mysql" "rabbitmq" "catalogue" "user" "shipping" "payment" "dispatch" "frontend")
ZONE_ID="Z025072226A39JCBZP3HB"
DOMAIN_NAME="moukthika.site"

for instance in "${INSTANCES[@]}"; do
  echo "🚀 Launching instance: $instance"

  INSTANCE_INFO=$(aws ec2 run-instances \
    --image-id "$AMI_ID" \
    --instance-type t3.micro \
    --security-group-ids "$SG_ID" \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" \
    --query "Instances[0]" \
    --output json)

  if [[ -z "$INSTANCE_INFO" ]]; then
    echo "❌ Failed to launch instance: $instance"
    continue
  fi

  INSTANCE_ID=$(echo "$INSTANCE_INFO" | jq -r '.InstanceId')

  if [[ -z "$INSTANCE_ID" || "$INSTANCE_ID" == "null" ]]; then
    echo "❌ Failed to get Instance ID for $instance"
    continue
  fi

  echo "⏳ Waiting for instance $INSTANCE_ID ($instance) to be running..."
  aws ec2 wait instance-running --instance-ids "$INSTANCE_ID"

  # Add a small wait to allow IP to be allocated
  sleep 5

  if [[ "$instance" == "frontend" ]]; then
    IP=$(aws ec2 describe-instances \
      --instance-ids "$INSTANCE_ID" \
      --query "Reservations[0].Instances[0].PublicIpAddress" \
      --output text)
  else
    IP=$(aws ec2 describe-instances \
      --instance-ids "$INSTANCE_ID" \
      --query "Reservations[0].Instances[0].PrivateIpAddress" \
      --output text)
  fi

  if [[ -z "$IP" || "$IP" == "None" ]]; then
    echo "❌ Failed to get IP address for $instance"
    continue
  fi

  echo "✅ $instance IP address: $IP"

  # Route53 DNS update
  echo "🔧 Updating Route53 record for $instance.$DOMAIN_NAME..."
  aws route53 change-resource-record-sets \
    --hosted-zone-id "$ZONE_ID" \
    --change-batch "{
      \"Comment\": \"Creating or updating record set for $instance\",
      \"Changes\": [{
        \"Action\": \"UPSERT\",
        \"ResourceRecordSet\": {
          \"Name\": \"$instance.$DOMAIN_NAME\",
          \"Type\": \"A\",
          \"TTL\": 120,
          \"ResourceRecords\": [{
            \"Value\": \"$IP\"
          }]
        }
      }]
    }"
done
