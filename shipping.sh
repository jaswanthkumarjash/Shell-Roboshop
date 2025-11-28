#!/bin/bash

START_TIME=$(date +%s)

FILE_PATH=$PWD

MYSQL_HOST=mysql.jaswanthjash12.shop

USERID=$(id -u)
if [ $USERID -ne 0 ]; then
    echo "ERROR:: You dont have root access"
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

dnf install maven -y &>> $LOG_FILE
VALIDATE $? "Installing maven"

id roboshop &>> $LOG_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    VALIDATE $? "Creating system user"
else
    echo -e "System user already exist ...$Y SKIPPING$N"
fi

mkdir -p /app 
VALIDATE $? "Creating app directory"

cd /app
VALIDATE $? "Moving into app directory"

curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>> $LOG_FILE
VALIDATE $? "Downloading shipping application"

rm -rf /app/* &>> $LOG_FILE
VALIDATE $? "Removing existing code"

unzip /tmp/shipping.zip &>> $LOG_FILE
VALIDATE $? "Unzipping the shipping application file"

mvn clean package &>> $LOG_FILE
VALIDATE $? "Installing dependencies"

mv target/shipping-1.0.jar shipping.jar 
VALIDATE $? "Moving shipping.jar file"

cp $FILE_PATH/shipping.service /etc/systemd/system/shipping.service
VALIDATE $? "Creating shipping service"

systemctl daemon-reload
VALIDATE $? "Daemon-reload"

systemctl enable shipping &>> $LOG_FILE
VALIDATE $? "Enable shipping service"

systemctl start shipping
VALIDATE $? "Start shipping service"

dnf install mysql -y &>> $LOG_FILE
VALIDATE $? "Installing mysql client"

mysql -h $MYSQL_HOST -uroot -pRoboShop@1 -e 'use cities' &>>$LOG_FILE
if [ $? -ne 0 ]; then
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/schema.sql &>>$LOG_FILE
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/app-user.sql  &>>$LOG_FILE
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/master-data.sql &>>$LOG_FILE
else
    echo -e "Shipping data is already loaded ... $Y SKIPPING $N"

fi

systemctl restart shipping
VALIDATE $? "Restarting shipping service"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))
echo "Total execution time of script is $TOTAL_TIME seconds"