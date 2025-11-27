#!/bin/bash

START_TIME=$(date +%s)

FILE_PATH=$PWD

USERID=$(( id -u ))
if [ $USERID -ne 0 ]; then
    echo "ERROR:: You are not root user"
    exit 1
fi

LOG_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
LOG_FILE="$LOG_FOLDER/$SCRIPT_NAME.log"

mkdir -p $LOG_FOLDER

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

VALIDATE () {
    if [ $1 -ne 0 ]; then
        echo -e "$2 ...$R FAILED$N" | tee -a $LOG_FILE
        exit 2
    else
        echo -e "$2 ...$G SUCCESS$N" | tee -a $LOG_FILE
    fi
}

cp $FILE_PATH/rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo
VALIDATE $? "Adding RabbitMQ repo"

dnf install rabbitmq-server -y &>> $LOG_FILE
VALIDATE $? "Installing RabbitMQ"

systemctl enable rabbitmq-server &>> $LOG_FILE
VALIDATE $? "Enabling Rabbitmq server"

systemctl start rabbitmq-server
VALIDATE $? "Start Rabbitmq server"

id roboshop &>> $LOG_FILE
v=$(id roboshop)
echo "$v"

if [ $? -ne 0 ]; then
    rabbitmqctl add_user roboshop roboshop123 &>> $LOG_FILE
    VALIDATE $? "Adding roboshop user"
else
    echo -e "Roboshop user already exists ...$Y SKIPPING$N"
fi

rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*" &>> $LOG_FILE
VALIDATE $? "Setting permissions"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))
echo "Total execution time is $TOTAL_TIME second"