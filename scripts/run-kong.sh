#!/bin/bash
set -e

if [ "$#" -ne 1 ]; then
  echo "Please run '$0 [kong version]'"
  echo "or         '$0 list'   to show all Kong versions available for testing."
  exit 1
fi
VER="$1"

cwd=$(pwd)
if [ ! -f "$cwd/kong/config/kong.yml" ]; then
    echo "Please run this script from 'perimeterx-kong-plugin' root folder."
    exit 1
fi


if [ "$VER" = "list" ]; then
    for d in `find "$cwd/scripts/" -name "Dockerfile.*"`
    do
        filename=$(basename -- "$d")
        # kong.2.8.0
        tmp=${filename#*.}
        # 2.8.0
        ver=${tmp#*.}
        echo "$ver"
    done
    exit 0
fi


dockerfile=$cwd/scripts/Dockerfile.kong.$VER
if [ ! -f "$dockerfile" ]; then
    echo "There is no Dockerfile for this Kong version: $VER"
    exit 1
fi

conf=$cwd/kong/config/kong.dev.yml
if [ ! -f "$conf" ]; then
    echo "There is no $conf Kong development configuration file. Please copy 'kong.yml' to 'kong.dev.yml' and adjust parameters."
    exit 1
fi


NAME=pxkong-$VER

docker rm -v -f "$NAME"
docker build -t "$NAME" -f "$dockerfile" .

docker run  \
    -e "KONG_DATABASE=off" \
    -e "KONG_PROXY_ACCESS_LOG=/dev/stdout" \
    -e "KONG_ADMIN_ACCESS_LOG=/dev/stdout" \
    -e "KONG_PROXY_ERROR_LOG=/dev/stderr" \
    -e "KONG_ADMIN_ERROR_LOG=/dev/stderr" \
    -e "KONG_ADMIN_LISTEN=0.0.0.0:8001, 0.0.0.0:8444 ssl" \
    -e "KONG_DECLARATIVE_CONFIG=/etc/kong/kong.yml" \
    -e "KONG_PLUGINS=bundled,perimeterx" \
    -p 8080:8000 \
    -p 8000:8000 \
    -p 8443:8443 \
    -p 8001:8001 \
    -p 8444:8444 \
    -v $(pwd)/:/tmp/px \
    -it --rm --name "$NAME" "$NAME"


   # -e "KONG_LOG_LEVEL=debug" \
