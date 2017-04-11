MeshbluRefCacheController = require './controllers/meshblu-ref-cache-controller'
httpSignature             = require '@octoblu/connect-http-signature'

class Router
  constructor: ({ @publicKey, @meshbluRefCacheService }) ->
    throw new Error 'Missing meshbluRefCacheService' unless @meshbluRefCacheService?
    throw new Error 'Missing publicKey' unless @publicKey?

  route: (app) =>
    meshbluRefCacheController = new MeshbluRefCacheController { @meshbluRefCacheService }

    app.get '/cache/:uuid/*', meshbluRefCacheController.get

    # order is important here
    app.use httpSignature.verify pub: @publicKey
    app.use httpSignature.gateway()

    app.post '/cache', meshbluRefCacheController.create

module.exports = Router
