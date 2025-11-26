#!/bin/bash

USERID=$(id -u)
if [ $USERID -ne 0 ]; then 
    echo "ERROR:: You dont have root access"
    exit 1
fi

LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"

mkdir -p $LOGS_FOLDER

echo "Script execution started at: $(date)" | tee -a $LOG_FILE

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

VALIDATION () {
    if [ $1 -ne 0 ]; then
        echo -e "$2 ...$R FAILURE$N"
        exit 1
    else
        echo -e "$2 ...$G SUCCESS$N"
    fi
}

dnf module disable nodejs -y
VALIDATE $? "Disabling existing nodejs version"

dnf module enable nodejs:20 -y
VALIDATE $? "Enabling nodejs version-20"

dnf install nodejs -y
VALIDATE $? "Installing nodejs"

useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
VALIDATE $? "Adding Roboshop system user"

mkdir /app
VALIDATE $? "Creating new directory"