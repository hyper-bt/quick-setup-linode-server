#!/bin/sh

# user variable
USER_CONF_PATH="conf/user.conf"

if [ ! -f ${USER_CONF_PATH} ]; then
    echo "Can't find the user config.";
fi

. ${USER_CONF_PATH}

scp -r ../setup root@${SERVER_IP}:/home/
