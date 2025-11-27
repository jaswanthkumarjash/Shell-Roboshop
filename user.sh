#!/bin/bash

START_TIME=$(date +%s)

FILE_PATH=$PWD

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOG_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
LOG_FILE="$LOG_FOLDER/$SCRIPT_NAME.log"

mkdir -p $LOG_FILE

USERID=$(id -u)
if [ $USERID -ne 0 ]; then
    echo "$R ERROR$N:: You are not root user"
    exit 1
fi

VALIDATE () {
    if [ $1 -ne 0 ]; then
        echo -e "$2 ...$R FAILED$N" | tee -a $LOG_FILE
        exit 1
    else
        echo -e "$2 ...$G SUCCESS$N" | tee -a $LOG_FILE
    fi
}

dnf module disable nodejs -y &>> $LOG_FILE
VALIDATE $? "Disabling existing nodejs version"

dnf module enable nodejs:20 -y &>> $LOG_FILE
VALIDATE $? "Enabling nodejs version 20"

dnf install nodejs -y &>> $LOG_FILE
VALIDATE $? "Installing nodejs"

id roboshop &>> $LOG_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "Roboshop system user" roboshop
    VALIDATE $? "Creating a system user"
else
    echo -e "System user already exist ...$Y SKIPPING$N"

mkdir -p /app
VALIDATE $? "Creating app directory"

curl -L -o /tmp/user.zip https://roboshop-artifacts.s3.amazonaws.com/user-v3.zip
VALIDATE $? "Downloading user application code"

cd /app
VALIDATE $? "Moving into application directory"

rm -rf /app/*
VALIDATE $? "Removing existing user application"

unzip /tmp/user.zip
VALIDATE $? "Unzipping the user application code"

npm install
VALIDATE $? "Installing the dependencies"

cp $PATH/user.service /etc/systemd/system/user.service
VALIDATE $? "Creating systemd service"

systemctl daemon-reload
VALIDATE $? "Daemon reload service"

systemctl enable user
VALIDATE $? "Enabling user service"

systemctl start user
VALIDATE $? "Starting user service"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))
echo "Total time taken to execute the script is $TOTAL_TIME seconds" | tee -a $LOG_FILE