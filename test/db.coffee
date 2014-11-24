deltabase = require('../lib/db/DeltaBase')
fs = require('fs')
chai = require('chai')
chai.should()
path = require('path')
async = require('async')

# Recursive directory removal lib. Somewhat dangerous in prod hence restricted to
# dev dependencies. But pretty useful for tearing down data folders after fixtures.
# http://stackoverflow.com/questions/12627586/is-node-js-rmdir-recursive-will-it-work-on-non-empty-directories
rmdir = require('rimraf')

# Can create a database
describe "DeltaBase", ()->

  testDbPath = 'testdb'
  docsPath = 'docs'
  db = null

  describe "#()", ()->

    # Highly hazardous code following...
    afterEach (done)->
      rmdir('data', ()->
        rmdir(testDbPath, done)
      )

    it 'should create a new database', ()->
      db = deltabase()
      db.should.exist()
      fs.existsSync('data').should.equal.true

    it 'should create a new database in a named path', ()->
      db = deltabase({path: testDbPath})
      db.should.exist()
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
        result.$meta.should.exist()
        result.$meta.filepath.should.equal(path.join(testDbPath, docsPath, '1', '1.json'))
        fs.readFile result.$meta.filepath, (err, result)->
          if (err)
            throw err
          result.toString().should.equal '{"foo":"bar"}'
          done()

    # TODO: Following commented until correct behaviour is determined. Is $meta even the right way
    # to go about it? Do we need to pass document keys around if they could be stored in $meta anyway?
    # Would it be useful to have custom meta properties? Should these be stored in a separate file next to
    # the document, which is therefore unversioned? Or should $meta actually be stored in the doc and
    # therefore participate in versioning...
    #it 'should never store the $meta property', (done)->

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
          err.should.exist()
          done()

    # The following is a safety precaution. Accidentally omitting the key or using something you
    # didn't mean to shouldn't result in unintended behaviour.
    it 'should fail to set a doc with a complex key', (done)->
      db.set testDoc, testDoc, (err, result)->
        err.should.exist()
        done()

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
        result.should.exist
        result.foo.should.equal('bar2')
        done()

    it 'should load a doc from filesystem if not already cached', (done)->
      # Recreate db to clean the index
      db = deltabase({path: testDbPath})
      db.get "2", (err, result)->
        if err
          throw err
        result.should.exist
        result.foo.should.equal('bar2')
        done()

    it 'should decorate the retrieved document with metadata', (done)->
      # Recreate db to clean the index
      db = deltabase({path: testDbPath})
      db.get "2", (err, result)->
        if err
          throw err
        result.$meta.should.exist()
        result.$meta.revision.should.equal(1)
        result.$meta.filepath.should.equal(path.join(testDbPath, docsPath, '2', '1.json'))
        done()

    it 'should cache the doc instance in memory in the index', (done)->
      # TODO: Whilst this is optimal behaviour, there are times when there could be unintended
      # consequences. If a doc was changed without calling update then we'd get a version out-of-sync
      # with the filesystem. However this does have the advantage that in a scenario where the DB
      # is syncing with other servers in a cloud environment, any instances that are lying around
      # will all get updated. Consumers need to be aware that values on an object   

      # Recreate db to clean the index
      db = deltabase({path: testDbPath})
      # Get the document twice
      db.get "2", (err, result)->
        if err
          throw err
        # Set an arbitrary and unsaved property
        result.$foo = 'bar'
        db.get "2", (err, result)->
          if err
            throw err
          result.$foo.should.equal('bar')
          done()

    it 'should fail to load a non-existent doc', (done)->
      db.get "eek", (err, result)->
        err.should.exist()
        done()
    # TODO: Test revision bumping (will be on update...)
