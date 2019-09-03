#!/bin/bash

NIC="enp10s0f0"
local_ip=$(ip addr | grep inet | grep ${NIC} | awk '{print $2;}' | sed 's|/.*$||')
DBPassword="123456"

install_mysql()
{
  sudo apt install -y ncurses-dev zlib1g zlib1g-dev 
  sudo apt install -y mysql-server mysql-client libmysqlclient-dev
  
  sudo mkdir -p /usr/local/mysql
  sudo chown wsong:wsong /usr/local/mysql

  ln -s /usr/include/mysql /usr/local/mysql/include
  ln -s /usr/lib/aarch64-linux-gnu /usr/local/mysql/lib
}

set_root_passwd()
{
  sudo systemctl stop mysql
  
  #mysql listen on local IP
  sudo sed -i "s/127.0.0.1/${local_ip}/g" /etc/mysql/mysql.conf.d/mysqld.cnf
  
  useradd mysql
  sudo /etc/init.d/mysql stop
  sudo mkdir -p /var/run/mysqld
  sudo chown mysql:mysql /var/run/mysqld
  sudo mysqld_safe --skip-grant-tables --skip-networking &
  
  #set user root passwd as 123456 of mysql
  mysql -uroot -e "update user set authentication_string=PASSWORD("${DBPassword}") where user='root';"
  mysql -uroot -e "update user set plugin="mysql_native_password" where user='root';"
  mysql -uroot -e "flush privileges;"
  
  #ps -elf | grep mysql
  mysql_pid=$(pgrep mysql)
  sudo kill -9 $mysql_pid
  
  sudo systemctl restart mysql
}
