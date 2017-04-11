{beforeEach, afterEach, describe, it} = global
{expect}      = require 'chai'
sinon         = require 'sinon'
request       = require 'request'
enableDestroy = require 'server-destroy'
Server        = require '../../src/server'
fsBlobStore   = require 'fs-blob-store'
streamToString = require 'stream-to-string'

describe 'GET /cache', ->
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
    @logFn = sinon.spy()
    serverOptions =
      port: undefined
      disableLogging: true
      logFn: @logFn
      publicKey: @publicKey

    @server = new Server serverOptions

    @server.run =>
      @serverPort = @server.address().port
      done()

  beforeEach ->
    @store = fsBlobStore './test/tmp'

  afterEach ->
    @server.destroy()

  describe 'posting a single key', ->
    beforeEach (done) ->
      @store.remove '87c32ca0-ae2b-4983-bcd4-9ce5500fe3c1/some/path', done

    beforeEach (done) ->
      uploadOptions =
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

      options =
        baseUrl: "http://localhost:#{@serverPort}"
        uri: '/cache/87c32ca0-ae2b-4983-bcd4-9ce5500fe3c1/some/path'
        json: true

      request.post uploadOptions, (error, uploadResponse, uploadBody) =>
        done error if error?
        request.get options, (error, @response, @body) =>
          done error

    it 'should return a 200', ->
      expect(@response.statusCode).to.equal 200

    it 'should get the cache file', ->
      expect(@body).to.equal 'foo'

  describe.only 'getting the whole device', ->
    beforeEach (done) ->
      @store.remove '87c32ca0-ae2b-4983-bcd4-9ce5500fe3c1/_', done

    beforeEach (done) ->
      uploadOptions =
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

      options =
        baseUrl: "http://localhost:#{@serverPort}"
        uri: '/cache/87c32ca0-ae2b-4983-bcd4-9ce5500fe3c1'
        json: true

      request.post uploadOptions, (error, uploadResponse, uploadBody) =>
        done error if error?
        request.get options, (error, @response, @body) =>
          done error

    it 'should return a 200', ->
      expect(@response.statusCode).to.equal 200

    it 'should get the cache file', ->
      expect(@body).to.deep.equal some: path: 'foo'
