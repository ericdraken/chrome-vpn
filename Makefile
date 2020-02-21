
build:
	docker build -t ericdraken/chrome-vpn:armv7 .

rebuild:
	docker build --no-cache -t ericdraken/chrome-vpn:armv7 .

bash:
	docker-compose run --service-ports --no-deps --rm chrome-vpn bash

up0:
	docker-compose up --remove-orphan

up1:
	docker-compose -f docker-compose-scale1.yaml up --remove-orphan

up1v:
	docker-compose -f docker-compose-scale1v.yaml up --remove-orphan

up2:
	docker-compose -f docker-compose-scale2.yaml up --remove-orphan

up3:
	docker-compose -f docker-compose-scale3.yaml up --remove-orphan

up4:
	docker-compose -f docker-compose-scale4.yaml up --remove-orphan

aapl:
	curl -sLD - -x localhost:3001 https://finance.yahoo.com/quote/AAPL/community?p=AAPL -o /dev/null -w '%{url_effective}'

ipinfo:
	curl -sLD - -x localhost:3001 https://ipinfo.io