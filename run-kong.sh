#!/bin/bash
set -e
NAME=pxkong

docker rm -v -f $NAME
docker build -t $NAME -f Dockerfile .

docker run  \
    -e "KONG_DATABASE=off" \
    -e "KONG_PROXY_ACCESS_LOG=/dev/stdout" \
    -e "KONG_ADMIN_ACCESS_LOG=/dev/stdout" \
    -e "KONG_PROXY_ERROR_LOG=/dev/stderr" \
    -e "KONG_ADMIN_ERROR_LOG=/dev/stderr" \
    -e "KONG_ADMIN_LISTEN=0.0.0.0:8001, 0.0.0.0:8444 ssl" \
    -e "KONG_DECLARATIVE_CONFIG=/etc/kong/kong.yml" \
    -e "KONG_PLUGINS=bundled,perimeterx" \
    -p 8000:8000 \
    -p 8443:8443 \
    -p 8001:8001 \
    -p 8444:8444 \
    -v $(pwd)/:/tmp/px \
    -it --rm --name $NAME $NAME


   # -e "KONG_LOG_LEVEL=debug" \
