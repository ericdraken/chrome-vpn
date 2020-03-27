
build:
	docker build -t ericdraken/chrome-vpn:armv7 .
rebuild:
	docker build --no-cache -t ericdraken/chrome-vpn:armv7 .
bash:
	docker-compose run --service-ports --no-deps --rm chrome-vpn bash

up0:
	docker-compose up --remove-orphan

up1:
	docker-compose -f docker-compose-scale1.yaml up --remove-orphan -d
down1:
	docker-compose -f docker-compose-scale1.yaml down
logs1:
	docker-compose -f docker-compose-scale1.yaml logs -f --tail 1000

up2:
	docker-compose -f docker-compose-scale2.yaml up --remove-orphan -d
down2:
	docker-compose -f docker-compose-scale2.yaml down
logs2:
	docker-compose -f docker-compose-scale2.yaml logs -f --tail 1000

up3:
	docker-compose -f docker-compose-scale3.yaml up --remove-orphan -d
down3:
	docker-compose -f docker-compose-scale3.yaml down
logs3:
	docker-compose -f docker-compose-scale3.yaml logs -f --tail 1000

up4:
	docker-compose -f docker-compose-scale4.yaml up --remove-orphan -d
down4:
	docker-compose -f docker-compose-scale4.yaml down
logs4:
	docker-compose -f docker-compose-scale4.yaml logs -f --tail 1000

aapl:
	curl -sLD - -x localhost:3001 https://finance.yahoo.com/quote/AAPL/community?p=AAPL -o /dev/null -w '%{url_effective}'

ipinfo:
	curl -sLD - -x localhost:3001 https://ipinfo.io