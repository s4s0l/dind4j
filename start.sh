#!/bin/bash
set -e
DAEMONPID=0
trap 'echo SIGTERM; kill ${!}; kill $DAEMONPID; exit 143' SIGTERM
trap 'echo SIGKILL; kill ${!}; kill $DAEMONPID; exit 137' SIGKILL
trap 'echo SIGINT;  kill ${!}; kill $DAEMONPID; exit 130' INT
dockerd --host=unix:///var/run/docker.sock --storage-driver=vfs &
DAEMONPID="$!"
while true; do
  docker version && break
  sleep 1
done
if [ -z ${RUNASUID+x} ]; then
    if [ ! -t 1 ]; then
        su -c "$*" & wait ${!}
    else
        su -c "$*"
    fi
else
    addgroup -g 997 docker
    chgrp docker /var/run/docker.sock
    adduser -u ${RUNASUID} -s /bin/bash -G docker -D user user
    if [ ! -t 1 ]; then
        su user -c "$*" & wait ${!}
    else
        su user -c "$*"
    fi
fi
