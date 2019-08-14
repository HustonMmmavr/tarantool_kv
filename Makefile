PORT := $(PROD_PORT)
ifeq ($(PROD_PORT),)
# default for tests 
	PORT := 7831
endif

build:
	sudo  docker build . -t test_api

run:
	sudo  docker run --rm -d --name test_api_v1 -p $(PORT):7831 -it test_api


run_tests:
	sudo docker exec -ti test_api_v1 tarantool /opt/tarantool/api_test.lua

stop: 
	sudo docker stop test_api_v1

get_log:
	sudo docker exec -ti test_api_v1 cat ./server.log
