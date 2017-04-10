class MeshbluRefCacheController
  constructor: ({@meshbluRefCacheService}) ->
    throw new Error 'Missing meshbluRefCacheService' unless @meshbluRefCacheService?

  hello: (request, response) =>
    { hasError } = request.query
    @meshbluRefCacheService.doHello { hasError }, (error) =>
      return response.sendError(error) if error?
      response.sendStatus(200)

module.exports = MeshbluRefCacheController
