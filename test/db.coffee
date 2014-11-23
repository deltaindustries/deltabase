deltabase = require('../lib/db/DeltaBase')
fs = require('fs')
should = require('should')

# Recursive directory removal lib. Somewhat dangerous in prod hence restricted to
# dev dependencies. But pretty useful for tearing down data folders after fixtures.
# http://stackoverflow.com/questions/12627586/is-node-js-rmdir-recursive-will-it-work-on-non-empty-directories
rmdir = require('rimraf')

# Can create a database
describe "DeltaBase", ()->

  testDbPath = 'testdb'

  describe "#()", ()->

    # Highly hazardous code follows...
    afterEach (done)->
      rmdir('data', ()->
        rmdir(testDbPath, done)
      )

    it 'should create a new database', ()->
      db = deltabase()
      db.should.be.ok
      fs.existsSync('data').should.equal.true
    it 'should create a new database in a named path', ()->
      db = deltabase({path: testDbPath})
      db.should.be.ok
      fs.existsSync('data').should.equal.false
      fs.existsSync('testdb').should.equal.true

  describe "#set()", ()->
    db = null
    beforeEach (done)->
      # TODO: Eventually, a zipped-up test database complete with indicies is probably the way to
      # go for more complex test scenarios
      db = deltabase({path: testDbPath})
      done()

    testDoc = { foo: 'bar' }

    it 'should store a document without error', (done)->
      db.set '1', testDoc, (err, result)->
        err.should.not.be.ok
        result.should.be.ok

  describe "#get()", ()->
    db = null
    beforeEach (done)->
      # TODO: Eventually, a zipped-up test database complete with indicies is probably the way to
      # go for more complex test scenarios
      db = deltabase({path: testDbPath })
      done()
