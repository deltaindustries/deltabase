###
Tests for Delta Core
###

fs = require('fs')
chai = require('chai')
chai.should()
expect = chai.expect
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
    it 'should end', (done)->
      delta = Delta()
      delta.end(done)
    # TODO: Further tests of other objects/services shutting down properly

describe "DeltaModule", ()->

  testModule = (module)->
    module.
      name("test123").
      # TODO: Explicitly test for this information beig used
      description("A test module").
      version("1.0.0")
    module

  describe "init", ()->
    it 'should register a module and return Delta', ()->
      delta = Delta().module testModule
      delta.isDelta().should.be.true

    it 'should fire the initialize event', ()->
      delta = Delta().module (module)->
        testModule(module).
          on('init', (e)->
            done()
          )
      .run()

    ###
    it 'must have a name', ()->
      delta = Delta().module (module)->
      expect()
    ###

    it 'should load a module from a folder', ()->
      delta = Delta().module('test/modules/testmodule1')
      delta.module.exists('testmodule1').should.be.true

    it 'should start an app from a folder', (done)->
      # TODO: Test defalt app loading (i.e. '/app')
      delta = Delta({ app: 'test/apps/delta'})
      delta.run (err, callback)->
        expect(err).should.not.exist
        delta.module "delta", (module)->
          module.hasConfigured.should.equal.true
          done()
