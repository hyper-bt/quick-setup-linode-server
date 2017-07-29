
#!/bin/bash

# user variable
USER_CONF_PATH="conf/user.conf"

if [ ! -f ${USER_CONF_PATH} ]; then
    echo "Can't find the user config.";
fi

. ${USER_CONF_PATH}

echo "Input domain name:";
read DOMAI_NNAME;
echo "Domain: ${DOMAI_NNAME}";

echo "Input root path:";
read ROOT_PATH;
echo "Root path: ${ROOT_PATH}";

sudo cp template/sub-domain.default template/sub-domain.default.tmp
TEMPLATE_DEFINE_SERVER_NAME=${DOMAI_NNAME}
TEMPLATE_DEFINE_PATH=$(echo ${ROOT_PATH} | sed 's/\//\\\//g') #replace special char
sudo sed -i -e "s/##TEMPLATE_DEFINE_SERVER_NAME##/${TEMPLATE_DEFINE_SERVER_NAME}/g" template/sub-domain.default.tmp
sudo sed -i -e "s/##TEMPLATE_DEFINE_PATH##/${TEMPLATE_DEFINE_PATH}/g" template/sub-domain.default.tmp

#move file
sudo mv template/sub-domain.default.tmp /etc/nginx/sites-available/${DOMAI_NNAME}
if [ ! -d ${ROOT_PATH} ]; then
    mkdir ${ROOT_PATH}
fi
sudo chown ${USER_NAME}:${USER_NAME} ${ROOT_PATH}

#create link to site-enable
rm /etc/nginx/sites-enabled/${DOMAI_NNAME}
ln -s /etc/nginx/sites-available/${DOMAI_NNAME} /etc/nginx/sites-enabled/${DOMAI_NNAME}

#reload and restart server
sudo service nginx reload
sudo service nginx restart
