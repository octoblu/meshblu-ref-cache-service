_           = require 'lodash'
async       = require 'async'
debug       = require('debug')('meshblu-ref-cache-service:meshblu-ref-cache-service')
GenericPool = require 'generic-pool'
When        = require 'when'
RedisNS     = require '@octoblu/redis-ns'
Redis       = require 'ioredis'

class MeshbluRefCacheService
  constructor: ({ @redisUri, @namespace }) ->
    @maxConnections = 10
    @minConnections = 1
    @idleTimeoutMillis ?= 60000
    @redisPool = @_createRedisPool { @maxConnections, @minConnections, @idleTimeoutMillis, @namespace, @redisUri }

  create: ({ uuid, key, data }, callback) =>
    async.each key, async.apply(@_saveBlob, uuid, data), callback

  get: ({ uuid, path }, callback) =>
    path = '/_' if _.isEmpty path
    redisKey = "#{uuid}#{path}"
    debug { uuid, path, redisKey }
    @redisPool.acquire().then (client) =>
      client.get redisKey, (error, data) =>
        @redisPool.release client
        return callback error if error?
        try
          data = JSON.parse data
        catch error

        return callback null, data if data?
        callback @_createError 'Not Found', 404
    .catch callback

  _saveBlob: (uuid, data, key, callback) =>
    callback = _.once callback

    if key == '_'
      partialData = data
    else
      partialData = _.get data, key

    pathKey = key.replace /\./, '/'
    # clear highlight parsing error /' # WONTFIX
    redisKey = "#{uuid}/#{pathKey}"
    debug { uuid, data, key, redisKey, partialData }
    return callback() unless partialData?
    @redisPool.acquire().then (client) =>
      client.set redisKey, JSON.stringify(partialData), (error, data) =>
        @redisPool.release(client)
        callback error, data
    .catch callback

  _createError: (message='Internal Service Error', code=500) =>
    error = new Error message
    error.code = code
    return error

  _createRedisPool: ({ maxConnections, minConnections, idleTimeoutMillis, evictionRunIntervalMillis, acquireTimeoutMillis, namespace, redisUri }) =>
    factory =
      create: =>
        return When.promise (resolve, reject) =>
          conx = new Redis redisUri, dropBufferSupport: true
          client = new RedisNS namespace, conx
          rejectError = (error) =>
            return reject error

          client.once 'error', rejectError
          client.once 'ready', =>
            client.removeListener 'error', rejectError
            resolve client

      destroy: (client) =>
        return When.promise (resolve, reject) =>
          @_closeClient client, (error) =>
            return reject error if error?
            resolve()

      validate: (client) =>
        return When.promise (resolve) =>
          client.ping (error) =>
            return resolve false if error?
            resolve true

    options = {
      max: maxConnections
      min: minConnections
      testOnBorrow: true
      idleTimeoutMillis
      evictionRunIntervalMillis
      acquireTimeoutMillis
    }

    pool = GenericPool.createPool factory, options

    pool.on 'factoryCreateError', (error) =>
      @emit 'factoryCreateError', error

    return pool

module.exports = MeshbluRefCacheService
