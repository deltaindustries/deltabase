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

# Always initialise a null delta without modules loading
# Testing actual individual modules comes later...

delta = null
nullDelta = ()->
  delta = Delta({modulePaths: []})

describe "Delta", ()->
  describe "#()", ()->
    it 'should create', ()->
      delta = nullDelta()
      expect(delta).to.exist
      delta.isDelta().should.be.true

describe "delta", ()->
  describe "#run()", ()->
    it 'should run', ()->
      delta = nullDelta()
      delta.run().should.be.ok

  describe "#end()", ()->
    it 'should end', (done)->
      delta = nullDelta()
      delta.end(done)
    # TODO: Further tests of other objects/services shutting down properly

  describe "chainability", ()->
    it 'should chain return functions', (done)->
      delta = nullDelta().run().end (err, result)->
        delta.isDelta().should.be.true
        done(err,result)

describe "DeltaModule", ()->

  testModule = (module)->
    module.
      name("test123").
      # TODO: Explicitly test for this information beig used
      description("A test module").
      version("1.0.0")
    module

  describe "initialization", ()->

    beforeEach nullDelta

    it 'should register a module and return Delta', ()->
      delta.module testModule
        .isDelta().should.be.true

    it 'must have a name', ()->
      expect(()->
        delta.module (module)->
      ).to.throw(Error)

    it 'should load a module from a folder', ()->
      delta
        .module('test/modules/testmodule1')
      delta.module.exists('testmodule1').should.be.true

  describe "config", ()->

    beforeEach nullDelta

    it 'should be configurable', ()->
      delta.module (module)->
        module.name('test')
          .config
            foo: 'bar'

  describe "events", ()->

    beforeEach nullDelta

    it 'should bind and emit a synchronous event', (done)->
      delta.
        module((module)->
          module.name('test1').on('foo', (e)->done())
        , (module)->module.emit('foo'))

    it 'should bind and emit an asynchronous event', (done)->
      delta.
        module((module)->
          module.name('test1').on('foo', (e, cb)->cb())
        , (module)->module.emit('foo', done))

    it 'should fire the initialize event', ()->
      delta.module((module)->
        testModule(module).
          on('init', (e)->
            done()
          )
      )
      .run()

    it 'should access module properties in an event as "this"', ()->
      delta.module (module)->
        testModule(module).
          on('init', (e)->
            @name.should.equal("test123")
            @description.should.equal("A test module")
            @version.should.equal("1.0.0")
          )
      .run()

  describe "activation", ()->

    beforeEach nullDelta

    it 'should activate a dependant module', ()->
      delta
        .module (module)->module.name('test1')
        .module (module)->module.name('test2').depends('test1')
        .activate('test2')
        .module.activated('test1').should.be.true

  describe "activation", ()->

  describe "apps", ()->

    it 'should scan modules when it loads', ()->
      delta = Delta()
      delta.module.exists('Delta.Web').should.be.true

    it 'should start an app from a folder', (done)->
      # TODO: Test defalt app loading (i.e. '/app')
      delta = Delta({ app: 'test/apps/delta', modulePaths: []})
      delta.run (err, callback)->
        expect(err).to.not.exist
        delta.module "delta", (module)->
          module.emit('test')
          module.passed.should.equal.true
          done()
