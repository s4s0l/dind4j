#!/bin/bash
rm -f /var/run/docker.pid
set -e
if [ -z ${SKIPDAEMON+x} ]; then
    DAEMONPID=0
    trap 'echo SIGTERM; kill ${!}; kill $DAEMONPID; exit 143' SIGTERM
    trap 'echo SIGKILL; kill ${!}; kill $DAEMONPID; exit 137' SIGKILL
    trap 'echo SIGINT;  kill ${!}; kill $DAEMONPID; exit 130' INT
    dockerd --host=unix:///var/run/docker.sock --storage-driver=aufs &
    DAEMONPID="$!"
    while true; do
      docker version && break
      sleep 1
    done
fi


if [ -z ${RUNASUID+x} ]; then
    if [ ! -t 1 ]; then
        su -c "$*" & wait ${!}
    else
        su -c "$*"
    fi
else

    if [ -z ${DOCKERGUID} ]; then
        addgroup  docker
    else
        #we remove ping group as i do not know what it does anyway and it has id 999
        delgroup ping
        addgroup -g $DOCKERGUID docker
    fi
    #if we run our own daemon we change it to docker group
    if [ -z ${SKIPDAEMON+x} ]; then
        chgrp docker /var/run/docker.sock
    fi

    adduser -u ${RUNASUID} -s /bin/bash -H -G docker -D user user

    if [ ! -d /home/user ]; then
        mkdir /home/user
        chown user /home/user
    fi

    if [ ! -t 1 ]; then
        su user -c "$*" & wait ${!}
    else
        su user -c "$*"
    fi
fi
