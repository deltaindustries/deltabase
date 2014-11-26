###
Tests for delta web server
###

fs = require('fs')
chai = require('chai')
chai.should()
expect = chai.expect
path = require('path')
async = require('async')
Delta = require('../lib/Delta')

describe "Delta.Web", ()->

  describe "server", ()->

    # TODO: Next two tests aren't actually checking the things they say they're checking

    ###
    it 'should start up a web server', (done)->
      Delta({ app: 'test/apps/delta_web'}).run done
    ###
    it 'should start up and shut down the web server when app ends', (done)->
      delta = Delta({ app: 'test/apps/delta_web'})
      delta.run((err, result)->
        expect(err).to.not.exist
        delta.end done
      )
  # TODO: Test two server instances running simultaneously on separate ports

  describe "requests", ()->

    delta = null
    beforeEach (done)->
      delta = Delta({ app: 'test/apps/delta_web'})
        .run done

    afterEach (done)->
      delta.end done

    ###
    it 'should serve an index page', (done)->
      # Configure an app
      # Create a home page doc (autocreated, testable by content module)
      # 
    it 'should serve an arbitrary document'
      # Configure an app
      # Create a home page doc (autocreated, testable by content module)

    it 'should permalink a document by hyphenating the document title', ()->
      # Create a "Foo Bar" page, see it served on /foo-bar (content+web modules)
      # TODO: Then an angular test that /foo-bar can be loaded dynamically

    it 'should report a 404 error page'

    it 'should include a script'
    it 'should compile and include a CoffeeScript file'
    # TODO: Separate test for CS compilation
    it 'should include a style sheet'
    it 'should compile and include a Stylus file'
    # TODO: Separate test for styl compilation
    ###