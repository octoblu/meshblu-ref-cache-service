MeshbluRefCacheController = require './controllers/meshblu-ref-cache-controller'

class Router
  constructor: ({ @meshbluRefCacheService }) ->
    throw new Error 'Missing meshbluRefCacheService' unless @meshbluRefCacheService?

  route: (app) =>
    meshbluRefCacheController = new MeshbluRefCacheController { @meshbluRefCacheService }

    app.get '/hello', meshbluRefCacheController.hello
    # e.g. app.put '/resource/:id', someController.update

module.exports = Router
