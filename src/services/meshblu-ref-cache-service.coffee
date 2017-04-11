_              = require 'lodash'
async          = require 'async'
aws            = require 'aws-sdk'
s3BlobStore    = require 's3-blob-store'
fsBlobStore    = require 'fs-blob-store'
stringToStream = require 'string-to-stream'

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

  create: ({ key, data }, callback) =>
    async.each key, async.apply(@_saveBlob, data), callback

  _saveBlob: (data, key, callback) =>
    fileKey = key.replace /\./, '/'
    # clear highlight parsing error /' # WONTFIX

    partialData = _.get data, key
    ws = @store.createWriteStream key: fileKey, callback
    stringToStream(partialData).pipe ws

  _createError: (message='Internal Service Error', code=500) =>
    error = new Error message
    error.code = code
    return error

module.exports = MeshbluRefCacheService
