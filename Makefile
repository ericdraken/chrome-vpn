
build:
	docker build -t ericdraken/chrome-vpn:armv7 .
rebuild:
	docker build --no-cache -t ericdraken/chrome-vpn:armv7 .
bash:
	docker-compose run --service-ports --no-deps --rm chrome-vpn bash

up0:
	docker-compose up --remove-orphan -d
up1:
	docker-compose -f docker-compose-scale.yaml up --remove-orphan --scale chrome-vpn=1 -d
up2:
	docker-compose -f docker-compose-scale.yaml up --remove-orphan --scale chrome-vpn=2 -d
up3:
	docker-compose -f docker-compose-scale.yaml up --remove-orphan --scale chrome-vpn=3 -d
up4:
	docker-compose -f docker-compose-scale.yaml up --remove-orphan --scale chrome-vpn=4 -d
up5:
	docker-compose -f docker-compose-scale.yaml up --remove-orphan --scale chrome-vpn=5 -d

down:
	docker-compose -f docker-compose-scale.yaml down
logs:
	docker-compose -f docker-compose-scale.yaml logs -f --tail 1000

aapl:
	curl -sLD - -x localhost:3001 https://finance.yahoo.com/quote/AAPL/community?p=AAPL -o /dev/null -w '%{url_effective}'

ipinfo:
	curl -sLD - -x localhost:3001 https://ipinfo.io