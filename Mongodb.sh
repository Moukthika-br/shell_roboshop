#!/bin/bash

source ./common.sh
app_name=Mongodb

check_root
cp Mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "Copying mongoDB repo"

dnf install mongodb-org -y  &>>$LOG_FILE
VALIDATE $? "Installing MongoDB server"

systemctl enable mongod &>>$LOG_FILE
VALIDATE $? "Enabling the MongoDB"

systemctl start mongod &>>$LOG_FILE
VALIDATE $? "starting the MongoDB"

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
VALIDATE $? "Editing MondoDB conf file for remote connections"

systemctl restart mongod &>>$LOG_FILE
VALIDATE $? "Restarting MongoDB"

print_time