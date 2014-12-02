// Test core database engine
var deltabase = require('../lib/DeltaBase');
var fs = require('fs');
var chai = require('chai');
var should = chai.should();
var expect = chai.expect;
var path = require('path');
var async = require('async');
var rmdir = require('rimraf');

// TODO: In general, start checking for specific types of error rather than just existence

describe("DeltaBase", function() {
  var testDbPath = 'testdb';
  var docsPath = 'docs';
  var db = null;
  describe("#()", function() {

    beforeEach(function(done) {
      rmdir('data', function() {
        rmdir(testDbPath, done);
      });
    });

    it('should create a new database', function(done) {
      deltabase(function(err, db){
        db.should.exist();
        fs.existsSync('data').should.equal(true);
        done();
      });
    });

    it('should create a new database in a named path', function(done) {
      deltabase({
        path: testDbPath
      }, function(err, db) {
        db.should.exist();
        fs.existsSync('data').should.equal(false);
        fs.existsSync('testdb').should.equal(true);
        done();
      });
    });

    it('should create synchronously', function() {
      var db = deltabase({ path: testDbPath });
      db.should.exist();
      // TODO: Some actual tests the get ops are queued
    });

  });

  var testDoc = null;

  function initTestDb(done) {
    testDoc = {
      foo: 'bar'
    };
    rmdir(testDbPath, function(err,result){
      db = deltabase({
        path: testDbPath
      }, done);
    });
  };

  describe("#set()", function() {

    beforeEach(initTestDb);

    it('should create a document without error', function(done) {
      db.set('1', testDoc, done);
    });

    it('should store the document in the file system and provide metadata', function(done) {
      return db.set('1', testDoc, function(err, result) {
        if (err) {
          throw err;
        }
        result.$meta.should.exist();
        result.$meta.filepath.should.equal(path.join(testDbPath, docsPath, '1', '1.json'));
        return fs.readFile(result.$meta.filepath, function(err, result) {
          if (err) {
            throw err;
          }
          result.toString().should.equal('{"foo":"bar"}');
          return done();
        });
      });
    });

    it('should assign a revision number of 1 to a new document', function(done) {
      return db.set('1', testDoc, function(err, result) {
        if (err) {
          throw err;
        }
        result.$meta.revision.should.equal(1);
        return done();
      });
    });

    it('should fail to overwrite a doc with the same id', function(done) {
      return db.set('1', testDoc, function(err, result) {
        if (err) {
          throw err;
        }
        return db.set('1', testDoc, function(err, result) {
          err.should.exist();
          return done();
        });
      });
    });

    it('should fail to set a doc with a complex key', function(done) {
      return db.set(testDoc, testDoc, function(err, result) {
        err.should.exist();
        return done();
      });
    });

  });

  describe("#get()", function() {

    beforeEach(function(done) {
      initTestDb(function() {
        var docs;
        docs = [
          [ "1", { foo: "bar1" } ],
          [ "2", { foo: "bar2" } ],
          [ "3", { foo: "bar3" } ]
        ];
        async.each(docs, function(doc, cb) {
          db.set(doc[0], doc[1], function(err, result) {
            if (err) {
              return cb(err);
            }
            return cb();
          });
        }, function(err) {
          done(err);
        });
      });
    });

    it('should get a doc by arbitrary id', function(done) {
      db.get("2", function(err, result) {
        if (err) {
          throw err;
        }
        result.should.exist;
        result.foo.should.equal('bar2');
        return done();
      });
    });

    it('should load a doc from filesystem if not already cached', function(done) {
      // Create a new deltabase instance so we know it's not caching (theoretically)
      deltabase({
        path: testDbPath
      }, function(err, db) {
        db.get("2", function(err, result) {
          if (err) return done(err);
          result.should.exist;
          result.foo.should.equal('bar2');
          done();
        });
      });
    });
    
    it('should decorate the retrieved document with metadata', function(done) {
      deltabase({
        path: testDbPath
      }, function(err, db) {
        db.get("2", function(err, result) {
          if (err) {
            throw err;
          }
          result.$meta.should.exist();
          result.$meta.revision.should.equal(1);
          result.$meta.filepath.should.equal(path.join(testDbPath, docsPath, '2', '1.json'));
          return done();
        });
      });
    });
    
    it('should cache the doc instance in memory in the index', function(done) {
      deltabase({
        path: testDbPath
      }, function(err, db) {
        db.get("2", function(err, result) {
          if (err) {
            throw err;
          }
          result.$foo = 'bar';
          db.get("2", function(err, result) {
            if (err) {
              throw err;
            }
            result.$foo.should.equal('bar');
            done();
          });
        });
      });
    });
    
    it('should fail to load a non-existent doc', function(done) {
      db.get("eek", function(err, result) {
        err.should.exist();
        done();
      });
    });

  });

  describe('#exists()', function(){
    beforeEach(initTestDb);

    it('should return false for a doc that doesn\'t exist', function(done){
      db.exists("eek", function(err, result) {
        expect(err).to.not.exist;
        result.should.equal(false);
        done();
      });
    });

    it('should return true for a doc that does exist', function(done){
      db.set('test', {foo:'bar'}, function(err,result) {
        db.exists('test', function(err, result) {
          expect(err).to.not.exist;
          result.should.equal(true);
          done();
        });
      });

    });

  });

  describe('#update()', function(){
    beforeEach(initTestDb);
  });

  describe('#unset()', function(){
    beforeEach(initTestDb);

    it('should remove an existing item', function(done){
      db.set('test', {foo:'bar'}, function(err,result){
        var path = result.$meta.filepath;
        db.unset('test', function(err,result){
          if (err) return done(err);
          expect(result).to.not.exist();
          fs.exists(path, function(result){
            result.should.be.false;
            db.get('test', function(err,result){
              err.should.exist;
              done();
            });
          });
        });
      });
    });

    it('should error if removing a non-existent item', function(done){
      db.unset('eek', function(err,result){
        err.should.exist;
        expect(result).to.not.exist;
        done();
      });
    });

  });

//        result.$meta.filepath.should.equal(path.join(testDbPath, docsPath, '1', '1.json'));

});
