express = require('express');
DeltaModule = require('./DeltaModule');

Delta = (options = {})->

  @isDelta = ()->true
  modules = {}
  modulePrecedence = []

  # TODO: What's going on here is a bit like DeltaIndex, make it a separate component
  # (loads of other indexing needs)
  addModule = (module)->
  
  api = {}

  init = ()->
    for m in modulePrecedence
      m.trigger('init')
    api

  api.run = ()=>
    init()
    api

  api.end = ()->
    for m in modulePrecedence
      m.trigger('end')
    api

  api.module = (mdescriptor)=>
    module = new DeltaModule()
    # Let module describe itself
    mdescriptor module.descriptor()
    # Add module to index
    # TODO: Look up existing modules
    addModule(module)
    api
  
  api

module.exports = Delta