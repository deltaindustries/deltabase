events = require('events')

class DeltaDescriptor
  constructor: (@module)->

  name: (name)->
    @module.name = name
    @

  description: (description)->
    @module.description = description
    @

  version: (version)->
    @module.version = version
    @

  on: (name, callback)->
    @module.on(name, callback)
    @

class DeltaModule extends events.EventEmitter

  name: ""
  description: ""
  version: ""

  descriptor: ()->
    return new DeltaDescriptor(@)

module.exports = DeltaModule