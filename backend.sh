source common.sh

if [ -z "$1" ]; then
  echo Password input missing
  exit
fi
MYSQL_ROOT_PASSWORD=$1

echo -e "${color} Disable NodeJs Default Version \e[0m"
dnf module disable nodejs -y &>>log_file
status_check

echo -e "${color} Enable NodeJs 18 Version \e[0m"
dnf module enable nodejs:18 -y &>>log_file
status_check

echo -e "${color} Installing NodeJs \e[0m"
dnf install nodejs -y &>>log_file
status_check

echo -e "${color} Copy Backend Service File \e[0m"
cp backend.service /etc/systemd/system/backend.service &>>log_file
status_check

id expense &>>log_file
if [ $? -ne 0 ]; then
  echo -e "${color} Add Application User \e[0m"
  useradd expense &>>log_file
  status_check
fi

if [ ! -d /app ]; then
  echo -e "${color} Create application Directory \e[0m"
  mkdir /app &>>log_file
  status_check
fi

echo -e "${color} Delete old application content \e[0m"
rm -rf /app/* &>>log_file
status_check

echo -e "${color} Download Application Content \e[0m"
curl -o /tmp/backend.zip https://expense-artifacts.s3.amazonaws.com/backend.zip &>>log_file
status_check

echo -e "${color} Extract Application Content \e[0m"
cd /app
unzip /tmp/backend.zip &>>log_file
status_check

echo -e "${color} Download NodeJs Dependencies \e[0m"
cd /app
npm install &>>log_file
status_check

echo -e "${color} Install Mysql Client to Load Schema \e[0m"
dnf install mysql -y &>>log_file
status_check

echo -e "${color} Load Schema \e[0m"
mysql -h mysql-dev.devopsb24.online -uroot -p${MYSQL_ROOT_PASSWORD} < /app/schema/backend.sql &>>log_file
status_check

echo -e "${color} Starting Backend Service \e[0m"
systemctl daemon-reload &>>log_file
systemctl enable backend &>>log_file
systemctl start backend &>>log_file
status_check
