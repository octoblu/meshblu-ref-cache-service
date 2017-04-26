_              = require 'lodash'
async          = require 'async'
aws            = require 'aws-sdk'
s3BlobStore    = require 's3-blob-store'
fsBlobStore    = require 'fs-blob-store'
stringToStream = require 'string-to-stream'
debug          = require('debug')('meshblu-ref-cache-service:meshblu-ref-cache-service')

class MeshbluRefCacheService
  constructor: ({ @s3AccessKey, @s3SecretKey, @s3BucketName }) ->

    if process.env.NODE_ENV == 'test'
      @store = fsBlobStore('./test/tmp')
    else
      client = new aws.S3
        accessKeyId: @s3AccessKey
        secretAccessKey: @s3SecretKey

      @store = s3BlobStore
        client: client
        bucket: @s3BucketName

  create: ({ uuid, key, data }, callback) =>
    async.each key, async.apply(@_saveBlob, uuid, data), callback

  get: ({ uuid, path }, callback) =>
    path = '/_' if _.isEmpty path
    filename = "#{uuid}#{path}"
    stream = @store.createReadStream key: filename
    callback null, stream

  _saveBlob: (uuid, data, key, callback) =>
    callback = _.once callback
    debug { data, key }
    fileKey = key.replace /\./, '/'
    # clear highlight parsing error /' # WONTFIX
    filename = "#{uuid}/#{fileKey}"

    if key == '_'
      partialData = data
    else
      partialData = _.get data, key
    return callback() unless partialData?
    @store.remove filename, =>
      ws = @store.createWriteStream key: filename, callback
      ws.on 'error', (error) =>
        console.error '_saveBlob', error.stack
        callback error
      stringToStream(JSON.stringify(partialData)).pipe ws

  _createError: (message='Internal Service Error', code=500) =>
    error = new Error message
    error.code = code
    return error

module.exports = MeshbluRefCacheService
