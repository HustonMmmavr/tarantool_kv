local tap = require('tap')
local httpcli = require('http.client')
local json = require('json')
local pathURI = 'http://localhost:7831/kv'

test = tap.test('api')

test:plan(12)

test:test('Check insert ok', function(subtest)
	local expectedData = json.encode({info = 'Created'})
	local expectedStatus = 201
	local body = json.encode({key = 'hi', value = {a = 2}})
	local resp = httpcli.post(pathURI, body)

	subtest:plan(2)
	subtest:is(resp.status, expectedStatus, 'status=created')
	subtest:is(resp.body, expectedData, 'data equal')
end)

test:test('Check insert bad request (json body incorrect)', function(subtest)
	local expectedData = json.encode({error = 'Bad request: json body incorrect'})
	local expectedStatus = 400
	local body = json.encode(nil)--{key = 'hi1', value = nil})
	local resp = httpcli.post(pathURI, body)

	subtest:plan(2)
	subtest:is(resp.status, expectedStatus, 'status=bad_request')
	subtest:is(resp.body, expectedData, 'data equal')
end)

test:test('Check insert bad request (data in json incorrect)', function(subtest)
	local expectedData = json.encode({error = 'Bad request: broken data in json'})
	local expectedStatus = 400

	subtest:plan(6)

	local body = json.encode({key = 'hi1', value = nil})
	local resp = httpcli.post(pathURI, body)
	subtest:is(resp.status, expectedStatus, 'status=bad_request')
	subtest:is(resp.body, expectedData, 'data equal')

	body = json.encode({key = nil, value = '5'})
	resp = httpcli.post(pathURI, body)
	subtest:is(resp.status, expectedStatus, 'status=bad_request')
	subtest:is(resp.body, expectedData, 'data equal')

	body = json.encode({key = 5, value = 'efdfs'})
	resp = httpcli.post(pathURI, body)
	subtest:is(resp.status, expectedStatus, 'status=bad_request')
	subtest:is(resp.body, expectedData, 'data equal')
end)

test:test('Check insert conflict', function(subtest) 
	local expectedData = json.encode({error = 'Conflict: duplicate record'})
	local expectedStatus = 409
	local body = json.encode({key = 'hi2', value = {a = 2}})
	local resp = httpcli.post(pathURI, body)

	subtest:plan(3)
	subtest:is(resp.status, 201, 'created record for dup')

	resp = httpcli.post(pathURI, body)
	subtest:is(resp.status, expectedStatus, 'status=conflict')
	subtest:is(resp.body, expectedData, 'data equal')
end)


test:test('Check update ok', function(subtest)
	local data = {value = {a = 2}}
	local body = json.encode(data)
	local expectedData = json.encode({info = 'Updated entity with key = hi3'})
	local expectedStatus = 200
	local resp = httpcli.post(pathURI, json.encode({key = 'hi3', value = {a = 3}}))

	subtest:plan(3)
	subtest:is(resp.status, 201, 'entity created')

	resp = httpcli.put(pathURI .. '/hi3', body)
	subtest:is(resp.status, expectedStatus, 'status=ok')
	subtest:is(resp.body, expectedData, 'data equal')
end)

test:test('Check update bad request (json body incorrect)', function(subtest)
	local data = nil
	local expectedData = json.encode({error = 'Bad request: json body incorrect'})
	local expectedStatus = 400
	local body = json.encode(data)
	local resp = httpcli.post(pathURI, json.encode({key = 'hi4', value = {a = 3}}))

	subtest:plan(3)
	subtest:is(resp.status, 201, 'entity created')

	resp = httpcli.put(pathURI .. '/hi4', body)
	subtest:is(resp.status, expectedStatus, 'status=bad request')
	subtest:is(resp.body, expectedData, 'data equal')
end)

test:test('Check update bad request (data in json incorrect)', function(subtest)
	local data = {value = nil}
	local expectedData = json.encode({error = 'Bad request: input json doesnt contains value'})
	local expectedStatus = 400
	local body = json.encode(data)
	local resp = httpcli.post(pathURI, json.encode({key = 'hi5', value = {a = 3}}))

	subtest:plan(3)
	subtest:is(resp.status, 201, 'entity created')

	resp = httpcli.put(pathURI .. '/hi5', body)
	subtest:is(resp.status, expectedStatus, 'status=bad request')
	subtest:is(resp.body, expectedData, 'data equal')
end)

test:test('Check update not found', function(subtest)
	local expectedData = json.encode({error = 'Not found: cant update, no such key'})
	local expectedStatus = 404
	local body = json.encode({value = {a = 'dfsd'}})
	local resp = httpcli.put(pathURI .. '/122', body)

	subtest:plan(2)
	subtest:is(resp.status, expectedStatus, 'status=not found')
	subtest:is(resp.body, expectedData, 'data equal')
end)

test:test('Check find ok', function(subtest)
	local data = {key = 'hi6', value = {a = 5}}
	local body = json.encode(data)
	local expectedData = json.encode({value = {a = 5}})
	local expectedStatus = 200

	local resp = httpcli.post(pathURI, body)

	subtest:plan(3)
	subtest:is(resp.status, 201, 'entity created')

	resp = httpcli.get(pathURI .. '/hi6')
	subtest:is(resp.status, expectedStatus, 'status=ok')
	subtest:is(resp.body, expectedData, 'data equal')
end)

test:test('Check find not found', function(subtest)
	local expectedData = json.encode({error = 'Not found: cant find, no such key'})
	local expectedStatus = 404

	local resp = httpcli.get(pathURI .. '/hi7')
	subtest:plan(2)

	subtest:is(resp.status, expectedStatus, 'status=not found')
	subtest:is(resp.body, expectedData, 'data equal')
end)

test:test('Check delete ok', function(subtest)
	local data = {key = 'hi8', value = {a = 5}}
	local body = json.encode(data)
	local expectedData = json.encode({info = 'deleted entity with key = hi8'})
	local expectedStatus = 200

	local resp = httpcli.post(pathURI, body)

	subtest:plan(3)
	subtest:is(resp.status, 201, 'entity created')

	resp = httpcli.delete(pathURI .. '/hi8')
	subtest:is(resp.status, expectedStatus, 'status=ok')
	subtest:is(resp.body, expectedData, 'data equal')
end)

test:test('Check delete not found', function(subtest)
	local expectedData = json.encode({error = 'Not found: cant delete, no such key'})
	local expectedStatus = 404

	local resp = httpcli.delete(pathURI .. '/hi9')
	subtest:plan(2)

	subtest:is(resp.status, expectedStatus, 'status=not found')
	subtest:is(resp.body, expectedData, 'data equal')
end)

test:check()