{beforeEach, afterEach, describe, it} = global

{expect}      = require 'chai'
sinon         = require 'sinon'
request       = require 'request'
enableDestroy = require 'server-destroy'
Server        = require '../../src/server'
Redis         = require 'ioredis'
RedisNS       = require '@octoblu/redis-ns'
UUID          = require 'uuid'

describe 'POST /cache', ->
  beforeEach ->
    @publicKey = '''-----BEGIN PUBLIC KEY-----
MFwwDQYJKoZIhvcNAQEBBQADSwAwSAJBAILmZ+FAnHRH5uxDCjuZNf4/NO1+RlnB
rgGbCwRSmrezo4kBnAcOEx54m18toGFLI40oHFazEgvOM3F1N3jxelkCAwEAAQ==
-----END PUBLIC KEY-----'''
    @privateKey = '''-----BEGIN RSA PRIVATE KEY-----
MIIBOgIBAAJBAILmZ+FAnHRH5uxDCjuZNf4/NO1+RlnBrgGbCwRSmrezo4kBnAcO
Ex54m18toGFLI40oHFazEgvOM3F1N3jxelkCAwEAAQJATs8rYbmFuJiFll8ybPls
QXuKgSYScv2hpsPS2TJmhgxQHYNFGc3DDRTRkHpLLxLWOvHw2pJ8EnlLIB2Wv6Tv
0QIhAP4MaMWkcCJNewGkrMUSiPLkMY0MDpja8rKoHTWsL9oNAiEAg+fSrLY6zB7u
xw1jselN6/qJXeGtGtduDu5cL6ztin0CIQDO5lBV1ow0g6GQPwsuHOBH4KyyUIV6
26YY9m2Djs4R6QIgRYAJVi0yL8kAoOriI6S9BOBeLpQxJFpsR/u5oPkps/UCICC+
keYaKc587IGMob72txxUbtNLXfQoU2o4+262ojUd
-----END RSA PRIVATE KEY-----'''

  beforeEach (done) ->
    @namespace = "test:ref-cache:#{UUID.v4()}"
    @redisUri = 'localhost'
    @logFn = sinon.spy()
    serverOptions = {
      port: undefined
      disableLogging: true
      @logFn
      @publicKey
      @redisUri
      @namespace
    }

    @server = new Server serverOptions

    @server.run =>
      @serverPort = @server.address().port
      done()

  beforeEach (done) ->
    @client = new RedisNS @namespace, new Redis @redisUri, dropBufferSupport: true
    @client.on 'ready', done

  afterEach ->
    @server.destroy()

  describe 'posting a single key', ->
    beforeEach (done) ->
      @client.del '87c32ca0-ae2b-4983-bcd4-9ce5500fe3c1/some/path', done
      return

    beforeEach (done) ->
      options =
        headers:
          'X-MESHBLU-UUID': '87c32ca0-ae2b-4983-bcd4-9ce5500fe3c1'
        uri: '/cache?key=some.path'
        baseUrl: "http://localhost:#{@serverPort}"
        json:
          some:
            path: 'foo'
        httpSignature:
          keyId: 'meshblu-webhook-key'
          key: @privateKey
          headers: [ 'date', 'X-MESHBLU-UUID' ]

      request.post options, (error, @response, @body) =>
        done error

    it 'should return a 201', ->
      expect(@response.statusCode).to.equal 201

    it 'should create a cache entry', (done) ->
      @client.get '87c32ca0-ae2b-4983-bcd4-9ce5500fe3c1/some/path', (error, data) =>
        return done error if error?
        expect(data).to.equal '"foo"'
        done()
      return # promises

  describe 'caching the whole device', ->
    beforeEach (done) ->
      @client.del '87c32ca0-ae2b-4983-bcd4-9ce5500fe3c1/_', done
      return

    beforeEach (done) ->
      options =
        headers:
          'X-MESHBLU-UUID': '87c32ca0-ae2b-4983-bcd4-9ce5500fe3c1'
        uri: '/cache?key=_'
        baseUrl: "http://localhost:#{@serverPort}"
        json:
          some:
            path: 'foo'
        httpSignature:
          keyId: 'meshblu-webhook-key'
          key: @privateKey
          headers: [ 'date', 'X-MESHBLU-UUID' ]

      request.post options, (error, @response, @body) =>
        done error

    it 'should return a 201', ->
      expect(@response.statusCode).to.equal 201

    it 'should create a cache file', (done) ->
      @client.get '87c32ca0-ae2b-4983-bcd4-9ce5500fe3c1/_', (error, data) =>
        return done error if error?
        expect(JSON.parse data).to.deep.equal some: path: 'foo'
        done()
      return # promises

  describe 'posting two keys', ->
    beforeEach (done) ->
      @client.del '87c32ca0-ae2b-4983-bcd4-9ce5500fe3c1/some/path', done
      return

    beforeEach (done) ->
      @client.del '87c32ca0-ae2b-4983-bcd4-9ce5500fe3c1/another/path', done
      return

    beforeEach (done) ->
      options =
        headers:
          'X-MESHBLU-UUID': '87c32ca0-ae2b-4983-bcd4-9ce5500fe3c1'
        uri: '/cache?key=some.path&key=another.path'
        baseUrl: "http://localhost:#{@serverPort}"
        json:
          some:
            path: 'foo'
          another:
            path: 'bar'
        httpSignature:
          keyId: 'meshblu-webhook-key'
          key: @privateKey
          headers: [ 'date', 'X-MESHBLU-UUID' ]

      request.post options, (error, @response, @body) =>
        done error

    it 'should return a 201', ->
      expect(@response.statusCode).to.equal 201

    it 'should create a cache entry', (done) ->
      @client.get '87c32ca0-ae2b-4983-bcd4-9ce5500fe3c1/some/path', (error, data) =>
        return done error if error?
        expect(data).to.equal '"foo"'
        done()
      return # promises

    it 'should create another cache file', (done) ->
      @client.get '87c32ca0-ae2b-4983-bcd4-9ce5500fe3c1/another/path', (error, data) =>
        return done error if error?
        expect(data).to.equal '"bar"'
        done()
      return # promises
