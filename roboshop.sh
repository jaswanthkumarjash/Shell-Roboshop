#!/bin/bash

AMI_ID="ami-09c813fb71547fc4f"
SG_ID="sg-010f0caf83cbf088a"
HOSTEDZONE_ID="Z01808731CH4W38TLY466"
DOMAIN_NAME="jaswanthjash12.shop"


for instance in $@
do
    INSTANCE_ID=$(aws ec2 run-instances --image-id $AMI_ID \
                    --instance-type t3.micro \
                    --security-group-ids $SG_ID \
                    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" \
                    --query 'Instances[0].InstanceId' --output text)

    if [ $instance != "frontend" ]; then
        IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID \
                --query 'Reservations[0].Instances[0].PrivateIpAddress' --output text)
        RECORD_NAME="$instance.$DOMAIN_NAME"

    else
        IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID \
                --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
        RECORD_NAME="$DOMAIN_NAME"
    fi

    aws route53 change-resource-record-sets \
        --hosted-zone-id $HOSTEDZONE_ID \
        --change-batch '
        {
            "Comment": "Updating record set"
            ,"Changes": [{
            "Action"              : "UPSERT"
            ,"ResourceRecordSet"  : {
                "Name"              : "'$RECORD_NAME'"
                ,"Type"             : "A"
                ,"TTL"              : 1
                ,"ResourceRecords"  : [{
                    "Value"         : "'$IP'"
                }]
            }
            }]
        }
        '

done