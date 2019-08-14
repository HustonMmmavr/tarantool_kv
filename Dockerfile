FROM tarantool/tarantool:1.10.2
COPY ./src/app.lua /opt/tarantool
COPY ./api_test/api_test.lua /opt/tarantool
CMD ["tarantool", "/opt/tarantool/app.lua"]