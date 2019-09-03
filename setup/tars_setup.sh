#!/bin/bash

set -e

#======================================================
# This script is to build and setup tars framework
# prerequirment is that mysql is installed and
# the password is set of root user
#======================================================

curdir=$(cd `dirname $0`;pwd)
taf_dir=${curdir}/TarsFramework

NIC="enp10s0f0"

#local_ip=`ifconfig -a|grep inet|grep -v 127.0.0.1|grep -v inet6|awk '{print $2}'|tr -d "addr:"`
#local_ip=`ifconfig -a | grep 10.110 | awk '{print $2}'| tr -d "addr:"`
local_ip=$(ip addr | grep inet | grep ${NIC} | awk '{print $2;}' | sed 's|/.*$||')
machine_name=$(cat /etc/hosts | grep ${local_ip} | awk '{print $2}')
DB_HOST=${local_ip}
MAIN_HOST=${local_ip}
DBPort=3306
DBUser="root"
DBPassword="123456"
DBTarsPass="tars2015"

install_dep()
{
	echo "--------------install dependency-----------------"
	apt-get install -y gcc g++ flex bison make cmake perl gcc zlibc gzip git libncurses5-dev
	apt-get install -y protobuf-c-compiler protobuf-compiler libprotobuf-dev libprotobuf-c-dev libprotoc-dev
	apt-get install -y libmariadb-client-lgpl-dev
	
	# nvm install
	wget -qO- https://raw.githubusercontent.com/creationix/nvm/v0.33.11/install.sh | bash
	source ~/.bashrc
	rm -f install.sh
	nvm --version
	nvm install v8.11.3
	npm install -g pm2 --registry=https://registry.npm.taobao.org
	#如果pm2库无法识别，执行下列命令：
	npm i -g pm2
}

download_taf()
{
	#download
	echo "--------------Download TarsFramework-----------------"
	cd ${curdir}
	if [ ! -d TarsFramework ]; then
	  git clone https://github.com/songvy/TarsFramework.git --recursive
	fi
}

compile_taf()
{
	#compile
	echo "--------------Start compile TarsFramework-----------------"
	cd ${taf_dir}/build
	./build.sh prepare
	./build.sh all
	echo "--------------Complete compile TarsFramework-----------------"
}

install_taf()
{
	# install
	echo "--------------Start to install TarsFramework-----------------"
	if [ -d /usr/local/tars ]; then
	  sudo rm -rf /usr/local/tars
        fi
	sudo mkdir -p /usr/local/tars
	sudo chown $(whoami):$(whoami) /usr/local/tars
	
	if [ -d /home/tarsproto/protocol ]; then
	  sudo rm -rf /home/tarsproto/protocol
	fi
	sudo mkdir -p /home/tarsproto/protocol
        sudo chown $(whoami):$(whoami) /home/tarsproto/protocol
	
	cd ${taf_dir}/build
	./build.sh install
	echo "--------------Complete install TarsFramework-----------------"
}

config_db()
{
	# config db
	echo "--------------Start to config db-----------------"
	cd ${taf_dir}/sql
	echo "+++++DB_HOST = ${DB_HOST}"
	echo "+++++MAIN_HOST = ${MAIN_HOST}"
	
	mysql -u${DBUser} -p${DBPassword} -e "grant all on *.* to 'tars'@'%' identified by '${DBTarsPass}' with grant option;"
	mysql -u${DBUser} -p${DBPassword} -e "grant all on *.* to 'tars'@'localhost' identified by '${DBTarsPass}' with grant option;"
	mysql -u${DBUser} -p${DBPassword} -e "grant all on *.* to 'tars'@'${machine_name}' identified by '${DBTarsPass}' with grant option;"
	mysql -u${DBUser} -p${DBPassword} -e "grant all on *.* to 'tars'@'${MAIN_HOST}' identified by '${DBTarsPass}' with grant option;"
	mysql -u${DBUser} -p${DBPassword} -e "flush privileges;"

	sed -i "s/192.168.2.131/${MAIN_HOST}/g" `grep 192.168.2.131 -rl ./*`
	sed -i "s/db.tars.com/${DB_HOST}/g" `grep db.tars.com -rl ./*`
	sed -i "s/10.120.129.226/${DB_HOST}/g" `grep 10.120.129.226 -rl ./*`
	sed -i "s/uroot/utars/g" exec-sql.sh
	sed -i "s/proot@appinside/ptars2015/g" exec-sql.sh
	
	chmod +x exec-sql.sh

	# the cmd will fail due to not config mysql
	echo "---plase exec exec-sql.sh in ${taf_dir}/sql"
	./exec-sql.sh
}

buid_package()
{
	echo "--------------build tars package-----------------"
	cd ${taf_dir}/build
	make framework-tar

	sudo mkdir -p /data/log/tars
	sudo mkdir -p /usr/local/app/tars
	sudo chown -R $(whoami):$(whoami) /usr/local/app /data/log/tars /home/tarsproto
	cp framework.tgz /usr/local/app/tars/
	cd /usr/local/app/tars
	tar zxvf framework.tgz

	echo "+++++DB_HOST = ${DB_HOST}"
	echo "+++++MAIN_HOST = ${MAIN_HOST}"
	sed -i "s/192.168.2.131/${MAIN_HOST}/g" `grep 192.168.2.131 -rl ./*`
	sed -i "s/db.tars.com/${DB_HOST}/g" `grep db.tars.com -rl ./*`
	sed -i "s/registry.tars.com/${MAIN_HOST}/g" `grep registry.tars.com -rl ./*`
	sed -i "s/web.tars.com/${MAIN_HOST}/g" `grep web.tars.com -rl ./*`
}

launch_taf()
{
	echo "--------------launch tars-----------------"
	sudo mkdir -p /data/tars/app_log
	sudo mkdir -p /data/tars/remote_app_log
	sudo chown -R $(whoami):$(whoami) /data/tars

	cd /usr/local/app/tars
	chmod +x tars_install.sh
	./tars_install.sh
	sudo ./tarspatch/util/init.sh

	#crontab -l > conf && echo "* * * * * /usr/local/app/tars/tarsnode/util/monitor.sh" >> conf && crontab conf && rm -f conf
	echo "* * * * * /usr/local/app/tars/tarsnode/util/monitor.sh" > conf && crontab conf && rm -f conf
}

install_tarsweb()
{
	echo "--------------install tarsWeb-----------------"
	cd ${curdir}
	git clone https://github.com/TarsCloud/TarsWeb.git
	cd TarsWeb
	sed -i "s/db.tars.com/${DB_HOST}/g" config/webConf.js
	sed -i "s/registry.tars.com/${MAIN_HOST}/g" config/tars.conf

	npm install --registry=https://registry.npm.taobao.org
	npm run prd
	echo "tarsWeb is runing, serve on http://${MAIN_HOST}:3000"
}

compile_module()
{
  echo "--------------build other modules-----------------"
  cd ${taf_dir}/build
  
  make tarsstat-tar
  make tarsnotify-tar
  make tarsproperty-tar
  make tarslog-tar
  make tarsquerystat-tar
  make tarsqueryproperty-tar
}

stop_taf()
{
  #stop tarsWeb
  pm2 stop all
  
  #stop tars
  cd /usr/local/app/tars
  cat > stop.sh << EOF
#!/bin/bash
tarsregistry/util/start.sh ;
tarsAdminRegistry/util/start.sh;
tarsnode/util/start.sh ;
tarsconfig/util/start.sh;
tarspatch/util/start.sh;
EOF

  chmod +x stop.sh
  ./stop.sh
}

delete_dir()
{
  rm -rf /usr/local/tars
  rm -rf /home/tarsproto/protocol
  rm -rf /data/log/tars
  rm -rf /usr/local/app/tars
  rm -rf /data/tars/app_log
  rm -rf /data/tars/remote_app_log
  
  rm -rf ${taf_dir}
  rm -rf ${curdir}/TarsWeb
}

start_taf()
{
  launch_taf
  cd ${curdir}/TarsWeb
  npm run prd
}

setup_taf()
{
  #install_dep
  download_taf
  compile_taf
  install_taf
  config_db
  buid_package
  launch_taf
  install_tarsweb
  compile_module
}

remove_taf()
{
  stop_taf
  delete_dir
}

case "$1" in
  setup)
        echo "Setup TarsFramework. "
        setup_taf
        ;;
  remove)
        echo "Remove TarsFramework. "
        remove_taf
        ;;
  start)
        echo "Start TarsFramework. "
		start_taf
        ;;
  stop)
        echo "Stop TarsFramework. "
        stop_taf
        ;;
  *)
        echo "Usage: $0 [setup|remove|start|stop]"
        ;;
esac

exit 0
