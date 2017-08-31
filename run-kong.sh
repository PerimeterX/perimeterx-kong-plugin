#!/bin/bash

if [[ $1 == "-r" || $1 == "--refresh" ]]; then
	docker exec -it kong kong reload
	exit 1
fi

if [[ $1 == "-s" || $1 == "--setup" ]]; then
	docker exec -it kong ln -s /plugins/perimeterx /usr/local/share/lua/5.1/kong/plugins/perimeterx
	docker exec -it kong kong migrations up
	docker exec -it kong kong start -c /etc/kong/kong.yml
	curl -i -X POST \
      --url http://localhost:8001/apis/ \
      --data 'name=example-api' \
      --data 'methods=GET' \
      --data 'upstream_url=http://testsite:3000'

    curl -i -X POST \
      --url http://localhost:8001/apis/example-api/plugins/ \
      --data 'name=perimeterx' \
      --data 'config.px_appId=APP_ID' \
      --data 'config.auth_token=AUTH_TOKEN' \
      --data 'config.cookie_secret=COOKIE_KEY' \
      --data 'config.ip_headers=X-Forwarded-For' \
      --data 'config.blocking_score=60' \
      --data 'config.block_enabled=true'
	exit 1
fi

docker rm -f kong
docker build -t pxkong .
cd dev && docker build -t itestsite .

docker-compose up -d


