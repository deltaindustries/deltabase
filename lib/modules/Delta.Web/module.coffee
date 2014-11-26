express = require('express')

module.exports = (module)->
  # Create an empty variable for expreas
  app = null
  server = null

  # TODO: Allow override of port through app config system
  module.config
    port: 3000

  module.on 'init', (e)->
    app = express()
  
  module.on 'run', (e, done)->
    # TODO: Queue up prioritised middleware and inject it in the run() event
    server = app.listen @config('port'), (err, result)->
      done()
  
  module.on 'end', (e, done)->
    server.close()
    server = null
    app = null
    done()
