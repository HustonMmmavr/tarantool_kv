local json = require('json')
local log = require('log')

box.cfg{
    log = './server.log',
    worker_pool_threads = 4
}

box.once('init_db1111', function() 
    log.info('init')
    local db = box.schema.space.create('kv_db', {
        format = {
            {name = 'key', type = 'string'},
            {name = 'value'}
        },
        if_not_exists = true
    })

    db:create_index(
        'primary', {
            type = 'hash',
            parts = {'key'}, 
            if_not_exists = true
    })
end)

local function bad_request(req, msg) 
    local resp = req:render{json = {error = 'Bad request: ' .. msg}}
    resp.status = 400
    return resp
end 

local function conflict(req, msg)
    local resp = req:render{json = {error = 'Conflict: ' .. msg}}
    resp.status = 409
    return resp
end

local function not_found(req, msg)
    local resp = req:render{json = {error = 'Not found: ' .. msg}}
    resp.status = 404 
    return resp
end 


local function insert(req)
    local res, data = pcall(function() return req:json() end)

    -- invalid json
    if (not res) or (data == nil) then
        log.info('Incorrect json')
        return bad_request(req, 'json body incorrect')
    end

    local key, val = data['key'], data['value']
    if (key == nil) or (type(key) ~= 'string') or (val == nil) then
        log.info('key or value missing')
        return bad_request(req, 'broken data in json')
    end

    local inserted, info =  pcall(function() 
        box.space.kv_db:insert{key, val}
    end)

    if not inserted then 
        log.info('key = %s already exists', key)
        return conflict(req, 'duplicate record')
    end

    log.info('inserted entity with key = %s', key)
    local resp = req:render{json = { info = 'Created'}}
    resp.status = 201
    return resp
end 

local function update(req) 
    local key = req:stash('id')

    local res, data = pcall(function() return req:json() end)
    -- invalid json
    if (not res) or (data == nil) then
        log.info('Incorrect json')
        return bad_request(req, 'json body incorrect')
    end

    local val = data['value']
    if val == nil then
        log.info('Sended value is empty')
        return bad_request(req, 'input json doesnt contains value')
    end
    
    local entity = box.space.kv_db:select{key}
    if table.getn(entity) == 0 then 
        log.info('no such entity with key %s', key)
        return not_found(req, 'cant update, no such key')
    end 

    local updatedEntity = box.space.kv_db:update(key, {{'=', 2, val}})
    log.info('updated entity with key = %s', key)
    return req:render{json = {info = 'Updated entity with key = ' .. key}} 
end

local function find(req) 
    local key = req:stash('id')

    local entity = box.space.kv_db:select{key}
    if table.getn(entity) == 0 then 
        log.info('no such entity with key %s', key)
        return not_found(req, 'cant find, no such key')
    end

    log.info('finded entity with key %s', key)
    return req:render{json = {value = entity[1][2]}}
end

local function remove(req) 
    local key = req:stash('id')

    local deletedEntity = box.space.kv_db:delete{key}
    if deletedEntity == nil then 
        log.info('No such entity with key %s', key)
        return not_found(req, 'cant delete, no such key')
    end

    log.info('Entity with key %s deleted', key)
    return req:render{json = {info = 'deleted entity with key = ' .. key}}
end

local httpd = require('http.server')
local srv = httpd.new("0.0.0.0", "7831")

srv:route({path = '/kv', method = 'POST'}, insert)
srv:route({path = '/kv/:id', method = 'GET'}, find)
srv:route({path = '/kv/:id', method = 'PUT'}, update)
srv:route({path = '/kv/:id', method = 'DELETE'}, remove)

srv:start()