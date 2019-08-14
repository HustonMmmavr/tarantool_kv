PORT := $(PROD_PORT)
ifeq ($(PROD_PORT),)
# default for tests 
	PORT := 7831
endif

build:
	docker build . -t test_api

run:
	docker run --rm -d --name test_api_v1 -p $(PORT):7831 -it test_api


run_tests:
	docker exec -ti test_api_v1 tarantool /opt/tarantool/api_test.lua

stop: 
	docker stop test_api_v1

get_log:
	docker exec -ti test_api_v1 cat ./server.log
