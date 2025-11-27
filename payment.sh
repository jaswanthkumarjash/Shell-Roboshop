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


dnf install python3 gcc python3-devel -y
VALIDATE $? "Installing python"

id roboshop &>> $LOG_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "Roboshop system user" roboshop
    VALIDATE $? "System user creation"
else
    echo -e "System user already exist ...$Y SKIPPING$N" | tee -a $LOG_FILE
fi

mkdir /app 
VALIDATE $? "Creating app directory"

curl -L -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip 
VALIDATE $? "Downloading payment application code"

cd /app 
VALIDATE $? "Moving into app directory"

unzip /tmp/payment.zip
VALIDATE $? "Unzipping payment application file"

pip3 install -r requirements.txt
VALIDATE $? "Installing dependencies"

cp $FILE_PATH/payment.service /etc/systemd/system/payment.service
VALIDATE $? "Creating parment service"

systemctl daemon-reload
VALIDATE $? "Daemon reload"

systemctl enable payment 
VALIDATE $? "Enable payment service"

systemctl start payment
VALIDATE $? "Start payment service"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))
echo "Total script execution time is $TOTAL_TIME seconds" | tee -a $LOG_FILE