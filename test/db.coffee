deltabase = require('../lib/db/DeltaBase')
fs = require('fs')

# Can create a database
describe "DeltaBase", ()->
  describe "#create()", ()->
    it 'should create a new database', ()->
      db = deltabase.create()
      db.should.be.ok
      fs.existsSync('data').should.equal.true
    it 'should create a new data folder', ()->
      db = deltabase.create({path: 'testdb'})
      db.should.be.ok
      fs.existsSync('data').should.equal.false
      fs.existsSync('testdb').should.equal.true
      # TODO: teardown should remove the folder...

  describe "#get()", ()->
    db = null
    beforeEach (done)->
      # TODO: Eventually, a zipped-up test database complete with indicies is probably the way to
      # go for more complex test scenarios
      db = deltabase.create({path: 'testdb'})

