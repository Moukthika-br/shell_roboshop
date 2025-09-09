#!/bin/bash
START_TIME=$(date + %s)
USERIDID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
LOGS_FOLDER="/var/log/shellscript-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$PWD

mkdir -p $LOGS_FOLDER
echo "Script started executing at: $(date)" | tee -a $LOG_FILE

#check the user has root privelages or not
if [ $USERID -ne 0 ]
then
    echo -e "$R ERROR:: Please run this script with root access $N" | tee -a $LOG_FILE
    exit 1 #give other than 0 upto 127
else
    echo "You are running with root access" | tee -a $LOG_FILE
fi

# validate functions takes input as exit status, what command they tried to install
VALIDATE(){
    if [ $1 -eq 0 ]
    then
        echo -e " $2 is ... $G SUCCESS $N" | tee -a $LOG_FILE
    else
        echo -e " $2 is ... $R FAILURE $N" | tee -a $LOG_FILE
        exit 1
    fi
}

dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "Disabling the  defaultnodejs"

dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "enabling the nodejs"

dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "Installing the nodejs"

id roboshop
if [ $? -ne 0 ]
then 
useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
VALIDATE $? "creating the application cart"

else 

echo -e "System user roboshop already created ... $Y SKIPPING $N"
fi 

mkdir -p /app  
VALIDATE $? "making the application "

curl -o /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/user-v3.zip  &>>$LOG_FILE
VALIDATE $? "Downloading the roboshop user application"

cd /app
unzip /tmp/cart.zip
VALIDATE $? "unzipping the file"

npm install &>>$LOG_FILE
VALIDATE $? "Installing dependencies"

cp  $SCRIPT_DIR/cart.service /etc/systemd/system/cart.service
VALIDATE $? "Copying cart service"

systemctl daemon-reload
systemctl enable cart
systemctl start cart
VALIDATE $? "Starting cart"

cp  $SCRIPT_DIR/Mongo.repo /etc/yum.repos.d/mongo.repo
dnf install mongodb-mongosh -y &>>$LOG_FILE
VALIDATE $? "Installing MongoDB client"

END_TIME=$(date + %s)

TOTAL_TIME=$(( $END_TIME - $START_TIME ))
echo -e "$TOTAL_TIME"
