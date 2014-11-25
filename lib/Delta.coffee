DeltaModule = require('./DeltaModule');
_ = require('lodash')
path = require('path')
async = require('async')

defaults = {
  app: 'app',
}

Delta = (options = {})->

  modules = {}
  modulePrecedence = []

  config = {}
  _.extend(config, defaults)
  _.extend(config, options)

  # TODO: What's going on here is a bit like DeltaIndex, make it a separate component
  # (loads of other indexing needs)
  addModule = (module)->
    modules[module.name] = module

  api = {}

  init = ()->
    for m in modulePrecedence
      m.trigger('init')
    api

  asyncModuleEvent = (name, callback)->
    async.eachSeries modulePrecedence, (m, cb)->
      m.trigger(name, cb)
    , callback

  api.isDelta = ()->true

  api.run = (callback)->
    init()
    asyncModuleEvent('run', callback)
    api

  api.end = (callback)->
    # TODO: Some further cleanup...
    asyncModuleEvent('end', callback)
    api

  api.module = (mdescriptor)->
    module = new DeltaModule()

    if _.isString(mdescriptor)
      module.name = mdescriptor.split('/').pop()
      mfile = require(path.resolve(mdescriptor) + "/module")
      mfile(module)

    else if _.isFunction(mdescriptor)
      # Let module describe itself
      mdescriptor module.descriptor()
      # Add module to index
      # TODO: Look up existing modules
    addModule(module)
    api
  
  api.module.exists = (name)->modules[name]?

  api

module.exports = Delta