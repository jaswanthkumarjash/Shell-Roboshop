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
    echo "ERROR:: You are not root user"
    exit 1
fi

VALIDATE () {
    if [ $1 -ne 0 ]; then
        echo "$2 ...$R FAILED$N" | tee -a $LOG_FILE
        exit 2
    else
        echo "$2 ...$G SUCCESS$N" | tee -a $LOG_FILE
    fi
}

dnf module disable nodejs -y &>> $LOG_FILE
VALIDATE $? "Disabling existing nodejs"

dnf module enable nodejs:20 -y &>> $LOG_FILE
VALIDATE $? "Enabling nodejs:20"

dnf install nodejs -y &>> $LOG_FILE
VALIDATE $? "Installing nodejs"

id roboshop &>> $LOG_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "Roboshop system user" roboshop
    VALIDATE $? "System user creation"
else
    echo "System user already exist ...$Y SKIPPING$N" | tee -a $LOG_FILE
fi

mkdir -p /app
VALIDATE $? "Creating app directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>> $LOG_FILE
VALIDATE $? "Downloading app code"

rm -rf /app/*
VALIDATE $? "Removing the existing code"

cd /app
VALIDATE $? "Moving into /app directory"

unzip /tmp/catalogue.zip &>> $LOG_FILE
VALIDATE $? "Unzipping the app code"

npm install &>> $LOG_FILE
VALIDATE $? "Installing dependencies"

cp ./catalogue.service /etc/systemd/system/catalogue.service
VALIDATE $? "Creating systemd service"

systemctl daemon-reload
VALIDATE $? "Daemon-reload"

systemctl enable catalogue &>> $LOG_FILE
VALIDATE $? "Enabling catalogue service"

systemctl start catalogue
VALIDATE $? "Starting catalogue service"

cp ./mongo.repo /etc/mongo.repo
VALIDATE $? "Adding mongo repo"

dnf install mongodb-mongosh -y &>> $LOG_FILE
VALIDATE $? "Installing mongo client"

INDEX=$(mongosh mongodb.daws86s.fun --quiet --eval "db.getMongo().getDBNames().indexOf('catalogue')")
if [ $INDEX -lt 0 ]; then
    mongosh --host $MONGODB_HOST </app/db/master-data.js &>>$LOG_FILE
    VALIDATE $? "Load catalogue products"
else
    echo "Datebase is already loaded ...$Y SKIPPING$N" | tee -a $LOG_FILE
fi

systemctl restart catalogue
VALIDATE $? "Restarting catalogue service"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))
echo "Total script execution time is $TOTAL_TIME" | tee -a $LOG_FILE
