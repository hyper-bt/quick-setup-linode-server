#!/bin/sh

# OS: Ubuntu 17.04
# PHP: 7.0
# Laravel:
# MySQL:

# config variable, switch command which exectue
SETUP_CONF_PATH="conf/config.conf"
# user variable
USER_CONF_PATH="conf/user.conf"

if [ ! -f ${SETUP_CONF_PATH} ]; then
    echo "Can't find the setup config.";
fi
if [ ! -f ${USER_CONF_PATH} ]; then
    echo "Can't find the user config.";
fi

. ${SETUP_CONF_PATH}
. ${USER_CONF_PATH}

# Allow use IPv6 but sets IPV4 as the precedence to apt-get
# https://askubuntu.com/questions/620317/apt-get-update-stuck-connecting-to-security-ubuntu-com
if [ "${CONFIG_USE_IPV4_APTGET}" = true ] ; then
    sudo sed -i -e "s/#precedence ::ffff:0:0\/96  100/precedence ::ffff:0:0\/96  100/g" /etc/gai.conf
fi

# Linode longview
if [ "${CONFIG_LINODE_LONGVIEW}" = true ] ; then
    sleep 1
    sudo apt-get install curl
    curl -s ${LONGVIEW_URL} | sudo bash
    sudo service longview restart
fi

# hostname
if [ "${CONFIG_HOSTNAME}" = true ] ; then
    sudo echo ${HOSTNAME} > /etc/hostname
    hostname -F /etc/hostname
    cp /etc/hosts /etc/hosts.bak
    sudo sed -i -e "s/127.0.1.1/#127.0.1.1/g" /etc/hosts
    sudo sed -i "/127.0.0.1/ a 127.0.1.1       ${HOSTNAME}" /etc/hosts
fi

# dns-nameservers
if [ "${CONFIG_DNS_NAMESERVERS}" = true ] ; then
    sed -i -e "s/dns-nameservers/#dns-nameservers/g" /etc/network/interfaces
    sed -i "/gateway/ a dns-nameservers ${DNS}" /etc/network/interfaces
fi

# timezone
if [ "${CONFIG_TIMEZONE}" = true ] ; then
    dpkg-reconfigure tzdata
    date
fi

#create user and set shh key
if [ "${CONFIG_CREATE_USER}" = true ] ; then
    sudo adduser ${USER_NAME} --gecos "First Last,RoomNumber,WorkPhone,HomePhone" --disabled-password
    echo "${USER_NAME}:${USER_PWD}" | sudo chpasswd
    sudo adduser ${USER_NAME} sudo

    #ssh key
    mkdir "/home/${USER_NAME}/.ssh"
    echo ${SSH_KEY} >> "/home/${USER_NAME}/.ssh/authorized_keys"
fi

#update sshd port, PubkeyAuthentication, PasswordAuthentication, PermitRootLogin
if [ "${CONFIG_SSHD_SETUP}" = true ] ; then
    sed -i -e "s/#Port 22/Port ${SSH_PORT}/g" /etc/ssh/sshd_config
    sed -i -e "s/PubkeyAuthentication yes/#PubkeyAuthentication no/g" /etc/ssh/sshd_config
    sed -i -e "s/PasswordAuthentication yes/#PasswordAuthentication no/g" /etc/ssh/sshd_config
    sed -i -e "s/PermitRootLogin yes/#PermitRootLogin no/g" /etc/ssh/sshd_config
    sudo service ssh reload
    sudo service ssh restart
fi

#firewall
if [ "${CONFIG_FIREWALL}" = true ] ; then
    sudo iptables -L
    cp template/iptables.firewall.rules template/iptables.firewall.rules.tmp
    sed -i -e "s/##TEMPLATE_DEFINE_PORT##/${SSH_PORT}/g" template/iptables.firewall.rules.tmp
    mv /etc/iptables.firewall.rules /etc/iptables.firewall.rules.bak
    mv template/iptables.firewall.rules.tmp /etc/iptables.firewall.rules
    sudo iptables-restore < /etc/iptables.firewall.rules
    sudo iptables -L
    cp template/firewall /etc/network/if-pre-up.d/firewall
    sudo chmod +x /etc/network/if-pre-up.d/firewall
fi


# ====================Server Basic==================== #
#package update
sleep 1
sudo apt-get update

#Fail2ban
if [ "${CONFIG_FAIL2BAN}" = true ] ; then
    sleep 1
    sudo apt-get -y install fail2ban
fi
# ====================Server Basic==================== #

# ==================== Web Server ==================== #
#nginx
if [ "${CONFIG_NGINX}" = true ] ; then
    sleep 1
    sudo apt-get -y install nginx nginx-extras
fi
# ==================== Web Server ==================== #

# ====================  Database  ==================== #
#mysql
if [ "${CONFIG_MYSQL}" = true ] ; then
    sleep 1
    sudo apt-get -y install mysql-server
    sudo mysql_install_db
    sudo mysql_secure_installation
fi
# ============ Disable Apparmor for MySQL ============ #
if [ "${CONFIG_DIABLE_MYSQL_APPARMOR}" = true ] ; then
    sudo service apparmor stop
    sudo ln -s /etc/apparmor.d/usr.sbin.mysqld /etc/apparmor.d/disable/
    sudo service apparmor restart
    sudo aa-status
fi
# ============ Disable Apparmor for MySQL ============ #
#sqlite
if [ "${CONFIG_SQLITE}" = true ] ; then
    sleep 1
    sudo apt-get -y install sqlite
fi
# ====================  Database  ==================== #

# ====================    PHP     ==================== #
#php
if [ "${CONFIG_PHP_CLI}" = true ] ; then
    sleep 1
    sudo apt-get -y install php7.0-cli
fi
if [ "${CONFIG_PHP_FPM}" = true ] ; then
    sleep 1
    sudo apt-get -y install php7.0-fpm
fi
if [ "${CONFIG_PHP_MYSQL}" = true ] ; then
    sleep 1
    sudo apt-get -y install php7.0-mysql
fi
if [ "${CONFIG_PHP_SQLITE}" = true ] ; then
    sleep 1
    sudo apt-get -y install php7.0-sqlite3
fi
if [ "${CONFIG_PHP_MBSTRING}" = true ] ; then
    sleep 1
    sudo apt-get -y install php7.0-mbstring
fi
if [ "${CONFIG_PHP_DOM}" = true ] ; then
    sleep 1
    sudo apt-get -y install php7.0-dom
fi
if [ "${CONFIG_PHP_XML}" = true ] ; then
    sleep 1
    sudo apt-get -y install php-xml
fi
if [ "${CONFIG_PHP_GD}" = true ] ; then
    sleep 1
    sudo apt-get -y install php7.0-gd
fi
# ====================    PHP     ==================== #

# ====================    Git     ==================== #
if [ "${CONFIG_GIT}" = true ] ; then
    sleep 1
    sudo apt-get -y install git
fi
# ====================    Git     ==================== #

# ====================  Composer  ==================== #
if [ "${CONFIG_COMPOSER}" = true ] ; then
    curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer
fi
# ====================  Composer  ==================== #

# ====================  Laravel   ==================== #
#Laravel
# if [ "${CONFIG_LARAVEL}" = true ] ; then
# fi
# ====================  Laravel   ==================== #

# ====================   Python   ==================== #
#python connect mysql
if [ "${CONFIG_PYTHON_MYSQL_CONNECT}" = true ] ; then
    sleep 1
    sudo apt-get install -y python-dev build-essential libssl-dev libffi-dev libxml2-dev libxslt1-dev zlib1g-dev python-pip libmysqld-dev
fi
#beatiful soup
if [ "${CONFIG_PYTHON_PACKAGE}" = true ] ; then
    sleep 3
    sudo pip install BeautifulSoup4
fi
# ====================   Python   ==================== #

# ==================== LNMP setup ==================== #
#PHP security
if [ "${CONFIG_PHP_SECURITY}" = true ] ; then
    sed -i -e "s/cgi.fix_pathinfo=1/;cgi.fix_pathinfo=0/g" /etc/php/7.0/fpm/php.ini
fi

#setting php are default with nginx
if [ "${CONFIG_NGINX_PHP}" = true ] ; then
    cp template/nginx.sites-available.default template/nginx.sites-available.default.tmp
    SED_ROOT_PATH=$(echo ${ROOT_PATH} | sed 's/\//\\\//g') #replace special char
    sed -i -e "s/##TEMPLATE_DEFINE_PATH##/${SED_ROOT_PATH}/g" template/nginx.sites-available.default.tmp
    cp -R /var/www/html ${ROOT_PATH}
    chown ${USER_NAME}:${USER_NAME} ${ROOT_PATH}
    sudo mv template/nginx.sites-available.default.tmp /etc/nginx/sites-available/default
fi

#change mysql port
if [ "${CONFIG_CHANGE_MYSQL_PORT}" = true ] ; then
    sed -i -e "s/3306/${MYSQL_PORT}/g" /etc/mysql/mysql.conf.d/mysqld.cnf
    service mysql restart
fi
# ==================== LNMP setup ==================== #

# ==================== MySQL Jobs ==================== #
if [ "${CONFIG_MYSQL_JOBS}" = true ] ; then
    # create user, database
    mysql -uroot -p${MYSQL_ROOT_PASSWORD} -e "CREATE DATABASE IF NOT EXISTS \`${MYSQL_NEW_DB_NAME}\` DEFAULT CHARACTER SET utf8mb4;"
    mysql -uroot -p${MYSQL_ROOT_PASSWORD} -e "create user '${MYSQL_NEW_USERNAME}'@'localhost' identified by '${MYSQL_NEW_PASSWORD}';"
    mysql -uroot -p${MYSQL_ROOT_PASSWORD} -e "GRANT ALL PRIVILEGES ON \`${MYSQL_NEW_DB_NAME}\`.* TO '${MYSQL_NEW_USERNAME}'@'localhost';"
    mysql -uroot -p${MYSQL_ROOT_PASSWORD} -e "FLUSH PRIVILEGES;"
fi
# ==================== MySQL Jobs ==================== #


