_ = require 'lodash'

class MeshbluRefCacheController
  constructor: ({@meshbluRefCacheService}) ->
    throw new Error 'Missing meshbluRefCacheService' unless @meshbluRefCacheService?

  create: (request, response) =>
    { key } = request.query
    data = request.body
    key = [ key ] unless _.isArray key
    @meshbluRefCacheService.create { key, data }, (error) =>
      return response.sendError(error) if error?
      response.status(201).end()

module.exports = MeshbluRefCacheController
