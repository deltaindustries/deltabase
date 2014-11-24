###
Tests for Delta Core
###

fs = require('fs')
chai = require('chai')
chai.should()
path = require('path')
async = require('async')

delta = require('../lib/Delta')

describe "Delta", ()->

  describe "#run()", ()->

    it 'should run', ()->
      delta.run()

    it 'should load a module', ()->