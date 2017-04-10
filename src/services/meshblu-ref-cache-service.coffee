class MeshbluRefCacheService
  doHello: ({ hasError }, callback) =>
    return callback @_createError('Not enough dancing!') if hasError?
    callback()

  _createError: (message='Internal Service Error', code=500) =>
    error = new Error message
    error.code = code
    return error

module.exports = MeshbluRefCacheService
