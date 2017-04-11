enableDestroy          = require 'server-destroy'
octobluExpress         = require 'express-octoblu'
Router                 = require './router'
MeshbluRefCacheService = require './services/meshblu-ref-cache-service'
httpSignature          = require '@octoblu/connect-http-signature'

class Server
  constructor: (options) ->
    {
      @logFn
      @disableLogging
      @port
      @publicKey
      @s3AccessKey
      @s3SecretKey
      @s3BucketName
    } = options
    throw new Error 'Missing publicKey' unless @publicKey?

  address: =>
    @server.address()

  run: (callback) =>
    app = octobluExpress({ @logFn, @disableLogging })

    app.use httpSignature.verify pub: @publicKey
    app.use httpSignature.gateway()

    meshbluRefCacheService = new MeshbluRefCacheService { @s3AccessKey, @s3SecretKey, @s3BucketName }
    router = new Router { meshbluRefCacheService }

    router.route app

    @server = app.listen @port, callback
    enableDestroy @server

  stop: (callback) =>
    @server.close callback

  destroy: =>
    @server.destroy()

module.exports = Server
