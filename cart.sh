#!/bin/bash

START_TIME=$(date +%s)

USERID=$(id -u)

if [ $USERID -ne 0 ]; then
    echo "ERROR:: You are not root user"
    exit 1
fi

FILE_PATH=$PWD

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

dnf module disable nodejs -y &>> $LOG_FILE
VALIDATE $? "Disabling existing nodejs"

dnf module enable nodejs:20 -y &>> $LOG_FILE
VALIDATE $? "Enabling nodejs version 20"

dnf install nodejs -y &>> $LOG_FILE
VALIDATE $? "Installing nodejs"

id roboshop &>> $LOG_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    VALIDATE $? "Creating system user"
else
    echo -e "System user already exist ...$y SKIPPING$N"
fi

mkdir -p /app
VALIDATE $? "Creating app directory"

curl -L -o /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip &>> $LOG_FILE
VALIDATE $? "Downloading cart application"

cd /app
VALIDATE $? "Moving into app directory"

rm -rf /app/* &>> $LOG_FILE
VALIDATE $? "Removing existing code"

unzip /tmp/cart.zip &>> $LOG_FILE
VALIDATE $? "Unzipping cart application code."

npm install &>> $LOG_FILE
VALIDATE $? "Installing dependencies"

cp $FILE_PATH/cart.service /etc/systemd/system/cart.service
VALIDATE $? "Creating cart service"

systemctl daemon-reload
VALIDATE $? "Daemon reload"

systemctl enable cart &>> $LOG_FILE
VALIDATE $? "Enabling cart service"

systemctl start cart
VALIDATE $? "Starting cart service"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))
echo "Total script execution time is $TOTAL_TIME seconds" | 