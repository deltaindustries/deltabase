###
Tests for Delta Core
###

fs = require('fs')
chai = require('chai')
chai.should()
path = require('path')
async = require('async')

Delta = require('../lib/Delta')

describe "Delta", ()->
  describe "#()", ()->
    it 'should create', ()->
      delta = Delta()

describe "delta", ()->
  describe "#run()", ()->
    it 'should run', ()->
      delta = Delta()
      delta.run().should.be.ok

  describe "#end()", ()->
    it 'should end', ()->
      delta = Delta()
      delta.end()
    # TODO: Further tests of other objects/services shutting down properly

describe "DeltaModule", ()->

  testModule = (module)->
    module.
      name("test123").
      # TODO: Explicitly test for this information beig used
      description("A test module").
      version("1.0.0")
    module

  describe "create", ()->
    delta = Delta().module testModule

  describe "init", (done)->
    delta = Delta().module (module)->
      testModule(module).
        on('init', (e)->
          done()
        )
    .run()


