deltabase = require('../lib/db/DeltaBase')
fs = require('fs')
should = require('should')
path = require('path')
async = require('async')

# Recursive directory removal lib. Somewhat dangerous in prod hence restricted to
# dev dependencies. But pretty useful for tearing down data folders after fixtures.
# http://stackoverflow.com/questions/12627586/is-node-js-rmdir-recursive-will-it-work-on-non-empty-directories
rmdir = require('rimraf')

# Can create a database
describe "DeltaBase", ()->

  testDbPath = 'testdb'
  db = null

  describe "#()", ()->

    # Highly hazardous code following...
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

  testDoc = null

  initTestDb = (done)->

    # TODO: Eventually, a zipped-up test database complete with indicies is probably the way to
    # go for more complex test scenarios
    db = deltabase({path: testDbPath})
    testDoc = { foo: 'bar' }
    done()

  destroyTestDb = (done)->
    # More hazard...
    db = null
    rmdir(testDbPath, done)

  describe "#set()", ()->
    beforeEach initTestDb
    afterEach destroyTestDb

    it 'should create a document without error', (done)->
      db.set '1', testDoc, done

    it 'should store the document in the file system and provide metadata', (done)->
      db.set '1', testDoc, (err, result)->
        if (err)
          throw err
        result.$meta.should.be.ok
        result.$meta.filepath.should.equal(path.join(testDbPath, 'docs', '1', '1.json'))
        fs.readFile result.$meta.filepath, (err, result)->
          if (err)
            throw err
          result.toString().should.equal '{"foo":"bar"}'
          done()

    it 'should assign a revision number of 1 to a new document', (done)->
      db.set '1', testDoc, (err, result)->
        if (err)
          throw err
        result.$meta.revision.should.equal(1)
        done()

    it 'should fail to overwrite a doc with the same id', (done)->
      db.set '1', testDoc, (err, result)->
        if (err)
          throw err
        db.set '1', testDoc, (err, result)->
          # TODO: Should check for specific error message?
          # TODO: Should double check that file contents weren't changed and index hasn't been overwritten?
          err.should.be.ok
          done()

    # The following is a safety precaution. Accidentally omitting the key or using something you
    # didn't mean to shouldn't result in unintended behaviour.
    it 'should fail to set a doc with a complex key', (done)->
      db.set testDoc, testDoc, (err, result)->
        err.should.be.ok
        done()

    # TODO: Test revision bumping
  describe "#get()", ()->
    beforeEach (done)->
      initTestDb ()->
        # Make some test docs
        docs = [
          [ "1", { foo: "bar1", } ],
          [ "2", { foo: "bar2", } ],
          [ "3", { foo: "bar3", } ]
        ]
        async.each docs, (doc, cb)->
          db.set(doc[0], doc[1], (err, result)->
            if err
              throw err
            cb()
          )
        , ()->
          done()

    afterEach destroyTestDb

    it 'should get a doc by arbitrary id', (done)->
      db.get "2", (err, result)->
        if err
          throw err
        result.should.be.ok
        result.foo.should.equal('bar2')
        done()

