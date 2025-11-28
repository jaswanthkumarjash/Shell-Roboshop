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


dnf install golang -y &>> $LOG_FILE
VALIDATE $? "Installing Golang"

id roboshop &>> $LOG_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "Roboshop system user" roboshop
    VALIDATE $? "System user creation"
else
    echo -e "System user already exist ...$Y SKIPPING$N" | tee -a $LOG_FILE
fi

mkdir -p /app 
VALIDATE $? "Creating app directory"

curl -L -o /tmp/dispatch.zip https://roboshop-artifacts.s3.amazonaws.com/dispatch-v3.zip &>> $LOG_FILE
VALIDATE $? "Downloading dispatch application"

cd /app 
VALIDATE $? "Moving into app directory"

rm -rf /app/* &>> $LOG_FILE
VALIDATE $? "Removing existing code"

unzip /tmp/dispatch.zip &>> $LOG_FILE
VALIDATE $? "Unzipping dispatch application file"

go mod init dispatch &>> $LOG_FILE
VALIDATE $? "Initialize dispatch module"

go get &>> $LOG_FILE
VALIDATE $? "Update the dependencies"

go build &>> $LOG_FILE
VALIDATE $? "Compile and make it executable"

cp $FILE_PATH/dispatch.service /etc/systemd/system/dispatch.service
VALIDATE $? "Creating dispatch service"

systemctl daemon-reload
VALIDATE $? "Daemon reload"

systemctl enable dispatch &>> $LOG_FILE
VALIDATE $? "Enabling dispatch service"

systemctl start dispatch
VALIDATE $? "Strating dispatch service"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))
echo "Total script execution time is $TOTAL_TIME seconds" | tee -a $LOG_FILE