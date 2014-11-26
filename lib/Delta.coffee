DeltaModule = require('./DeltaModule');
_ = require('lodash')
path = require('path')
async = require('async')
fs = require('fs')
defaults =
  modulePaths: [ 'lib/modules' ]

Delta = (options = {})->

  modules = {}
  activeModules = {}
  modulePrecedence = []

  config = {}
  _.extend(config, defaults)
  _.extend(config, options)

  services = {}

  # TODO: What's going on here is a bit like DeltaIndex, make it a separate component
  # (loads of other indexing needs ... e.g. translations, virtual filesystem, ...)
  # TODO: Also, all of this module handling should go off in a ModuleManager component... x 
  addModule = (module)->
    if !module.name? || !_.isString(module.name) || !module.name.length
      throw new Error("Module must have a name " + module)
    modules[module.name] = module

  api = {}

  activateModule = (module)->
    for m in module.dependencies
      if (!modules[m])
        throw new Error("Module '#{m}' is unknown and is a dependency of #{module.name}")
      activateModule(modules[m])
    if (!api.module.activated(module))
      modulePrecedence.unshift(module)
      activeModules[module.name] = module

  init = ()->
    # TODO: Modules should be able to configure both these services (and add their own services)
    # Services should be able to access delta to call other services ...
    # And some automatic handling of client/server stuff should be nicely wrapped up in there...
    api.service("db", new require('./db/DeltaBase')())
    api.service("vfs", new require('./vfs/DeltaFiles')())
    if config.app? && config.app.length
      api.activate(config.app)
    for m in modulePrecedence
      m.emit('init')
    api

  asyncModuleEvent = (name, callback)->
    async.eachSeries modulePrecedence, (m, cb)->
      m.emit(name, cb)
    , callback

  api.isDelta = ()->true

  api.service = (name, service)->
    if !service?
      return services[name]
    services[name] = service

  api.run = (callback)->
    init()
    asyncModuleEvent('run', callback)
    api

  api.end = (callback)->
    # TODO: Some further cleanup...
    asyncModuleEvent('end', callback)
    api

  api.module = (mdescriptor, callback)->
    if _.isString(mdescriptor)
      if modules[mdescriptor]?
        module = modules[mdescriptor]

      else
        module = new DeltaModule()
        module.origin = mdescriptor
        module.name = mdescriptor.split('/').pop()
        mfile = require(path.resolve(mdescriptor + "/module"))
        mfile(module.descriptor())

    else if _.isFunction(mdescriptor)
      module = new DeltaModule()
      module.origin = "function"
      # Let module describe itself
      mdescriptor module.descriptor()

    # Add module to index
    addModule(module)
    callback?(module)
    api
  
  api.module.exists = (name)->modules[name]?
  api.module.activated = (module)->activeModules[if _.isString(module) then module else module.name]?

  ###
  Activates a module
  ###
  api.activate = (mdescriptor, callback)->
    api.module(mdescriptor, (module)->
      callback?(module)
      activateModule(module)
    )

  # TODO: Needs to be more async. Things get tricky...

  for p in config.modulePaths
    readModules = (file)->
      modulePath = p + '/' + file
      api.module(modulePath)
    for file in fs.readdirSync(p)
      readModules(file)

  api

module.exports = Delta