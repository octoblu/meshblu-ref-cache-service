enableDestroy          = require 'server-destroy'
octobluExpress         = require 'express-octoblu'
Router                 = require './router'
MeshbluRefCacheService = require './services/meshblu-ref-cache-service'

class Server
  constructor: (options) ->
    {
      @logFn
      @disableLogging
      @port
      @publicKey
      @redisUri
      @namespace
    } = options
    throw new Error 'Missing publicKey' unless @publicKey?
    throw new Error 'Missing redisUri' unless @redisUri?
    throw new Error 'Missing namespace' unless @namespace?

  address: =>
    @server.address()

  run: (callback) =>
    app = octobluExpress({ @logFn, @disableLogging })

    meshbluRefCacheService = new MeshbluRefCacheService { @redisUri, @namespace }
    router = new Router { meshbluRefCacheService, @publicKey }

    router.route app

    @server = app.listen @port, callback
    enableDestroy @server

  stop: (callback) =>
    @server.close callback

  destroy: =>
    @server.destroy()

module.exports = Server
