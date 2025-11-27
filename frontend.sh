#!/bin/bash

START_TIME=$(date +%s)

FILE_PATH=$PWD

USERID=$(id -u)
if [ $USERID -ne 0 ]; then
    echo "ERROR:: You are not root user"
    exit 1
fi

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOG_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
LOG_FILE="$LOG_FOLDER/$SCRIPT_NAME.log"

mkdir -p $LOG_FOLDER

VALIDATE () {
    if [ $1 -ne 0 ]; then
        echo -e "$2 ...$R FAILED$N" | tee -a $LOG_FILE
        exit 2
    else
        echo -e "$2 ...$G SUCCESS$N" | tee -a $LOG_FILE
    fi 
}

dnf module disable nginx -y &>> $LOG_FILE
VALIDATE $? "Disabling existing nginx version"

dnf module enable nginx:1.24 -y &>> $LOG_FILE
VALIDATE $? "Enabling nginx version 1.24"

dnf install nginx -y &>> $LOG_FILE
VALIDATE $? "Installing nginx"

systemctl enable nginx &>> $LOG_FILE
VALIDATE $? "Enabling nginx service" 

systemctl start nginx
VALIDATE $? "Starting nginx service"

rm -rf /usr/share/nginx/html/* &>> $LOG_FILE
VALIDATE $? "Removing existing nginx page"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>> $LOG_FILE
VALIDATE $? "Downloading frontend application"

cd /usr/share/nginx/html/
VALIDATE $? "Moving into nginx frontend code directory"

unzip /tmp/frontend.zip &>> $LOG_FILE
VALIDATE $? "Unzipping frontend application code"

rm /etc/nginx/nginx.conf &>> $LOG_FILE
VALIDATE $? "Removing existing nginx configuration"

cp $FILE_PATH/nginx.conf /etc/nginx/nginx.conf
VALIDATE $? "Creating new nginx configuration"

systemctl restart nginx
VALIDATE $? "Restarting nginx service"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))
echo "Total script execution time is $TOTAL_TIME seconds" | tee -a $LOG_FILE