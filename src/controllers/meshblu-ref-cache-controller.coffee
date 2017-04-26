_ = require 'lodash'

class MeshbluRefCacheController
  constructor: ({@meshbluRefCacheService}) ->
    throw new Error 'Missing meshbluRefCacheService' unless @meshbluRefCacheService?

  create: (request, response) =>
    uuid = request.header 'X-MESHBLU-UUID'
    { key } = request.query
    data = request.body
    key = [ key ] unless _.isArray key
    @meshbluRefCacheService.create { uuid, key, data }, (error) =>
      return response.sendError(error) if error?
      response.status(201).end()

  get: (request, response) =>
    { uuid } = request.params
    path = request.path.replace("/cache/#{uuid}", '')
    @meshbluRefCacheService.get { uuid, path }, (error, stream) =>
      return response.sendError(error) if error?
      stream.once 'error', (error) =>
        error.code = 404 if error.code == 'ENOENT'
        error.code = 404 if error.code == 'NoSuchKey'
        return response.sendError(error) if error?
      stream.pipe(response)

module.exports = MeshbluRefCacheController
