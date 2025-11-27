#!/bin/bash

USERID=$(id -u)
if [ $USERID -ne 0 ]; then
    echo "ERROR:: You are not a root user to run this script"
    exit 1
fi
FILE_PATH=$PWD
LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"

mkdir -p $LOGS_FOLDER

echo "Script execution started at: $(date)" | tee -a $LOG_FILE

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

cp $FILE_PATH/mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "Adding mongo repo"

dnf install mongodb-org -y &>> $LOG_FILE
VALIDATE $? "Installing MongoDB"

systemctl enable mongod &>> $LOG_FILE
VALIDATE $? "Enabling mongod service"

systemctl start mongod
VALIDATE $? "Starting mongod service"

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
VALIDATE $? "Allowing remote connections to MongoDB"

systemctl restart mongod 
VALIDATE $? "Restarting mongod service"