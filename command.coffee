envalid        = require 'envalid'
SigtermHandler = require 'sigterm-handler'
Server         = require './src/server'
FetchPublicKey = require 'fetch-meshblu-public-key'

envConfig = {
  PORT: envalid.num({ default: 80, devDefault: 3000 })
  S3_ACCESS_KEY: envalid.str()
  S3_SECRET_KEY: envalid.str()
  S3_BUCKET_NAME: envalid.str()
  MESHBLU_PUBLIC_KEY_URI: envalid.str()
}

class Command
  constructor: ->
    env = envalid.cleanEnv process.env, envConfig
    @serverOptions = {
      port          : env.PORT
      s3AccessKey   : env.S3_ACCESS_KEY
      s3SecretKey   : env.S3_SECRET_KEY
      s3BucketName  : env.S3_BUCKET_NAME
      publicKeyUri  : env.MESHBLU_PUBLIC_KEY_URI
    }

  panic: (error) =>
    console.error error.stack
    process.exit 1

  run: =>
    new FetchPublicKey().fetch @serverOptions.publicKeyUri, (error, response) =>
      return @panic error if error?
      @serverOptions.publicKey = response.publicKey
      server = new Server @serverOptions
      server.run (error) =>
        return @panic error if error?

        { port } = server.address()
        console.log "MeshbluRefCacheService listening on port: #{port}"

      sigtermHandler = new SigtermHandler()
      sigtermHandler.register server.stop

command = new Command()
command.run()
