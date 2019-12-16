
build:
	docker build -t ericdraken/chrome-vpn:armv7 .

rebuild:
	docker build --no-cache -t ericdraken/chrome-vpn:armv7 .