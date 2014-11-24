###
Tests for delta web server
###

fs = require('fs')
chai = require('chai')
chai.should()
path = require('path')
async = require('async')

delta = require('../lib/Delta')

describe "Delta.Web", ()->

  describe "#run()", ()->

    it 'should start a web server', (done)->
      delta.run({ app: 'test/apps/delta_web'}, done)

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
