enableDestroy      = require 'server-destroy'
octobluExpress     = require 'express-octoblu'
MeshbluAuth        = require 'express-meshblu-auth'
Router             = require './router'
MeshbluRefCacheService = require './services/meshblu-ref-cache-service'

class Server
  constructor: (options) ->
    { @logFn, @disableLogging, @port } = options
    { @meshbluConfig } = options
    throw new Error 'Missing meshbluConfig' unless @meshbluConfig?

  address: =>
    @server.address()

  run: (callback) =>
    app = octobluExpress({ @logFn, @disableLogging })

    meshbluAuth = new MeshbluAuth @meshbluConfig
    app.use meshbluAuth.auth()
    app.use meshbluAuth.gateway()

    meshbluRefCacheService = new MeshbluRefCacheService
    router = new Router {@meshbluConfig, meshbluRefCacheService}

    router.route app

    @server = app.listen @port, callback
    enableDestroy @server

  stop: (callback) =>
    @server.close callback

  destroy: =>
    @server.destroy()

module.exports = Server
