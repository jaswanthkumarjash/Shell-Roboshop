#!/bin/bash

START_TIME=$(date +%s)

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOG_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
LOG_FILE="$LOG_FOLDER/$SCRIPT_NAME.log"

mkdir -p $LOG_FOLDER

USERID=$(id -u)
if [ $USERID -ne 0 ]; then
    echo -e "$R ERROR$N:: You are not root user"
    exit 1
fi

VALIDATE () {
    if [ $1 -ne 0 ]; then
        echo -e "$2 ...$R FAILED$N" | tee -a $LOG_FILE
        exit 2
    else
        echo -e "$2 ...$G SUCCESS$N" | tee -a $LOG_FILE
    fi
}

dnf module disable redis -y &>> $LOG_FILE
VALIDATE $? "Disabling existing redis version"

dnf module enable redis:7 -y &>> $LOG_FILE
VALIDATE $? "Enabling redis version 7"

dnf install redis -y &>> $LOG_FILE
VALIDATE $? "Installing redis"

sed -i -e 's/127.0.0.1/0.0.0.0/g' -e '/protected/ c protected-mode no/' /etc/redis/redis.conf
VALIDATE $? "Allowing remote connections to redis and changing from protected-mode from yes to no"

systemctl enable redis &>> $LOG_FILE
VALIDATE $? "Enabling redis service"

systemctl start redis
VALIDATE $? "Starting redis service" 

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))
echo -e "Total time taken to execute the script: $TOTAL_TIME"