MeshbluRefCacheController = require './controllers/meshblu-ref-cache-controller'

class Router
  constructor: ({ @meshbluRefCacheService }) ->
    throw new Error 'Missing meshbluRefCacheService' unless @meshbluRefCacheService?

  route: (app) =>
    meshbluRefCacheController = new MeshbluRefCacheController { @meshbluRefCacheService }

    app.post '/cache', meshbluRefCacheController.create

module.exports = Router
