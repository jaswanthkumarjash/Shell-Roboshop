#!/bin/bash

START_TIME=$(date +%s)

USERID=$(id -u)
if [ $? -ne 0 ]; then
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

dnf install mysql-server -y &>> $LOG_FILE
VALIDATE $? "Installing Mysql server"

systemctl enable mysqld &>> $LOG_FILE
VALIDATE $? "Enabling Mysql service"

systemctl start mysqld &>> $LOG_FILE
VALIDATE $? "Starting Mysql service"

mysql_secure_installation --set-root-pass RoboShop@1 &>> $LOG_FILE
VALIDATE $? "Password setting for root user"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))
echo "TOtal execution time is $TOTAL_TIME seconds"