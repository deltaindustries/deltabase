AsyncEventEmitter = require('async-eventemitter')

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

  depends: ()->
    for m in arguments
      @module.dependencies.push(m)
    @

  config: (defaults)->
    for k,v of defaults
      @module.config.set(k,v)
    @

class DeltaModule extends AsyncEventEmitter

  name: ""
  description: ""
  version: ""

  constructor: ()->
    super
    @dependencies = []

    # Module config will get way more complex than this (and sometimes needs to be gettable and settable
    # Delta-wide) but for now this is passing the required tests...
    _configs = {}
    @config = (key)->_configs[key]
    @config.set = (key, val)->_configs[key] = val

  descriptor: ()->
    return new DeltaDescriptor(@)

module.exports = DeltaModule