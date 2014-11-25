express = require('express')

module.exports = (module)->
  # Create an empty variable for expreas
  app = null
  
  # TODO: Allow override of port through app config system
  module.config
    port: 3000

  module.on 'init', (e)->
    app = express()
  
  module.on 'run', (done)->
    # TODO: Queue up prioritised middleware and inject it in the run() event
    app.listen module.config.port, (err, result)->
      done()
  
  module.on 'end', (done)->
    app.close()
    done()
