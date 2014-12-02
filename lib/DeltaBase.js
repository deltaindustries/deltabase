/**
 * Module dependencies.
 */
var fs = require('fs');
var path = require('path');
var _ = require('lodash');
var async = require('async');

/**
 * Create a DeltaBase instance.
 *
 * @return {Function}
 * @api public
 */
function DeltaBase(options, callback) {
  if (options == null) {
    options = {};
  }
  var dbpath = (_ref = options.path) != null ? _ref : 'data';
  var docspath = path.join(dbpath, 'docs');
  var indexpath = path.join(dbpath, 'index');
  this.paths = {
    db: dbpath,
    docs: docspath,
    index: indexpath
  };

  // Async initialzation

  // Set up a queue of operations for when the database is initialized
  // TODO: Test the queue
  this._ready = false;
  this._queued = [];

  var db = this;

  // Process the queue, set the ready flag, fire the callback
  function onReady() {
    // Signal if there was a fault
    if (this._readyError) {
      if (callback != null)
        callback(this._readyError)
      return;
    }

    // Process the queue
    this._ready = true;
    async.series(db._queued, function(err,result){
      // NOT passing any errors since these should have been originally handled by the caller
      if (callback != null)
        callback(null, db);
    });
  }

  // Initalize database folders if not created
  fs.exists(dbpath, function(result){
    // No init needed
    if (result) 
      return onReady();

    // Make all the paths we need
    var paths = [dbpath,docspath,indexpath];
    // (Series is important here so dbpath DEFINITELY creates first...)
    async.eachSeries(paths, function(path, cb){
      fs.mkdir(path, cb);
    }, function(err,result){
      // Trap any errors preventing readiness
      if (err) {
        db._readyError = err;
      }
      onReady();
    });
  });

  // Primary index of doc ids
  this.index = {};
  // Secondary indices which get generated and cached (in files in indexpath)
  this.indexes = {};

  /*
  Indicies are constructed as follows:
  {
    crit1: {
      false: [ { id: "doc1", crit1: false } ],
      true: [ { id: "doc2", crit1: true } ]
    }
  }
  
  - Any time a new doc is added to the primary index, iterate over all the indicies to add it in appropriate spots
  - If a query results in a previously unseen index, create a new one, and index all known documents into it
  
  TODO: Extract indexing out to a DeltaIndex class
   */

  /**
   * Query constructor
   */
  queryApi = function(db) {};

}

// Spider thru any indexes to index the document at the right nodes
// TODO: Normalize the coffee script weirdness of this
function spiderIndexes(crits, doc) {
  var _results = [];
  // Loop through partitions we know about
  for (var crit in crits) {
    var partitions = crits[crit];

    // Check doc's current value for the criteria
    // TODO: toString() is a slightly naive case which will work for simple
    // field values but gets us in trouble if dealing with more complex objects
    var critVal = doc[crit].toString();
    _results.push((function() {
      var _results1 = [];
      for (var key in partitions) {
        var val = partitions[key];
        // Skip until finding the right key
        if (key !== critVal) {
          continue;
        }
        // So the value at this point could either be an array of results
        // (in which case we've found an index to which to add the doc) or could
        // be further criteria for a deeply nested index; not sure if this is truly
        // necessary but with large datasets probably don't want to be intersecting huge
        // arrays from two different filter criteria.
        if (_.isArray(val)) {
          _results1.push(val.push(doc));
        } else {
          // Recursive search
          _results1.push(spiderIndicies(val, doc));
        }
      }
      return _results1;
    })());
  }
  return _results;
}

/**
 * Add a document to primary and secondary indexes
 * 
 * @param {String} id
 * @param {*} doc
 * @api private
 */
DeltaBase.prototype.addToIndex = function(id, doc) {
  // Add to primary index
  this.index[id] = doc;
  // Begin spidering at top level of secondary index
  spiderIndexes(this.indexes);
};

/**
 * Remove a document from primary and secondary indexes
 * 
 * @param {String} id
 * @param {*} doc
 * @api private
 */
DeltaBase.prototype.removeFromIndex = function(id, doc) {
  // Add to primary index
  delete this.index[id];
  // Begin spidering at top level of secondary index
  // TODO: unspiderIndexes(this.indexes);
};

/**
 * Build a local path on which to save a document
 *
 * @param {String} id
 * @param {*} doc
 * @param {Function} callback
 * @api private
 */
DeltaBase.prototype.filePathForDoc = function(id, doc, callback) {
  if (_.isFunction(doc)) {
    callback = doc;
  }
  var docpath = path.join(this.paths.docs, id);
  // TODO: Manage revisions properly
  // Maybe doc should be up a level and revisions are in subfolders. Will look cleaner and be easier to lookup
  // the canonical versiopn.
  var rev = 1;
  var filepath = path.join(docpath, rev + ".json");
  // Check if document folder exists and create if not
  // TODO: Start keeping a list of docpaths so don't have to perform this fs exists for every op
  // ... in fact only ever need to create the docpath with a 'set' op
  fs.exists(docpath, function(result) {
    if (result) {
      return callback(null, filepath);
    }
    fs.mkdir(docpath, function(err, result) {
      if (err) {
        return callback(err);
      }
      return callback(null, filepath);
    });
  });
};

/**
 * Stores a document in the store on the given key and fires callback(err, result) when complete.
 *
 * @param {String} id
 * @param {*} doc
 * @param {Function} callback
 */
DeltaBase.prototype.set = function(id, doc, callback, overwrite) {
  var $meta, text;
  if (!_.isString(id)) {
    return callback(new Error('Document id must be a string, got: ' + id + ' (' + typeof id + ')'));
  }
  // Create a text representation of the document, stripping out any meta properties.
  text = JSON.stringify(doc, function(key,val){
    if (key[0]==="$") {
      return undefined;
    }
    return val;
  });
  $meta = {
    revision: 1
  };
  var db = this;
  // Get path on which to save it
  this.filePathForDoc(id, doc, function(err, filePath) {
    if (err) {
      return callback(err);
    }
    $meta.filepath = filePath;
    doc.$meta = $meta;
    fs.exists(filePath, function(result) {
      if (result && !overwrite) {
        return callback(new Error('Document already exists with id: "' + id + '"'));
      }
      fs.writeFile(filePath, text, function(err) {
        if (err) {
          return callback(err);
        }
        // Finally index the document
        db.addToIndex(id, doc);
        // TODO: Result should eventually include more metadata about the item ... e.g. revision numbers
        return callback(null, doc);
      });
    });
  });
};

/**
 * Gets a document from the specified key and invokes callback(err, result) when done.
 *
 * @param {String} id
 * @param {*} doc
 * @param {Function} callback
 */
DeltaBase.prototype.get = function(id, callback) {
  if (!_.isString(id)) {
    return callback(new Error('Document id must be a string, got: ' + id + ' (' + typeof id + ')'));
  }
  // Return immediately if the document is in memory
  // TODO: Can produce unexpected behaviour. Consider setImmediate() instead.
  if (this.index[id] != null) {
    return callback(null, this.index[id]);
  }
  // Otherwise try to load from fs
  // TODO: This results in folders being created for non-existent Ids, even though a document
  // isn't created.
  var db = this;
  this.filePathForDoc(id, function(err, filePath) {
    if (err) {
      return callback(err);
    }
    fs.readFile(filePath, function(err, result) {
      var doc;
      if (err) {
        return callback(err);
      }
      // Parse result
      // TODO: Test for corrupt file behaviour, add try/catch
      doc = JSON.parse(result.toString());
      doc.$meta = {
        revision: 1,
        filepath: filePath
      };
      // Cache document in memory indexes
      db.addToIndex(id, doc);
      return callback(null, doc);
    });
  });
};

/**
 * Check if a document exists, invokes the callback with true or false.
 *
 * @param {String} id
 * @param {Function} callback
 */
DeltaBase.prototype.exists = function(id, callback) {
  // TODO: Slow op, can shortcut this to an fs.exists call rather than loading the whole item,
  // unless it's already in the index.
  this.get(id, function(err,result){
    if (err) return callback(null, false);
    callback(null, true);
  });
};

/**
 * Remove a document from the store and from indexes. Errors if the document doesn't exist.
 *
 * @param {String} id
 * @param {Function} callback
 */
DeltaBase.prototype.unset = function(id, callback) {
  var db = this;
  // TODO: Again, don't necessarily need to get the doc (although at some point might be good
  // to do this for security or validation purposes, but maybe in an ODM layer rather than here..)
  this.get(id, function(err,doc){
    if (err) return callback(err);
    fs.unlink(doc.$meta.filepath, function(err,result){
      if (err) return callback(err);
      db.removeFromIndex(id, doc);
      return callback();
    });
  });
};
/** 
 * Update a set of fields on a document in the store and trigger a reindex.
 *
 * @param {String} id
 * @param {Object} fields
 * @param {Function} callback
 */
DeltaBase.prototype.update = function(id, updates, callback) {
  var db = this;
  this.get(id, function(err,doc){
    for (var key in updates) {
      doc[key] = updates[key];
    }
    db.set(id, doc, function(err,result){
      if (err) return callback(err);
      // TODO: Implement a slightly optimised 'updateIndex'.
      db.removeFromIndex(id, result);
      db.addToIndex(id, result);
      return callback(null, result);
    }, true);
  });
};

/** Return a DeltaQuery object which can be used to query the store */
DeltaBase.prototype.query = function(options) {};
/** Acquire a lock on a document pending further operations */
DeltaBase.prototype.lock = function(id, callback) {};

/* TODO: This guarantees that no other server will modify the doc while you are working with it.
   Should deep clone instances to ensure that not even another async process will modify fields 
   unexpectedly. Maybe a "snapshot" command could be used for this. The lesson is to only ever
   hold onto DB objects for as short a time as possible... */

/**
 * Expose convenience method for construction.
 */
module.exports = function(arg1, arg2){
  var callback = _.isFunction(arg1) ? arg1 : arg2;
  var options = _.isFunction(arg1) ? {} : arg1;
  return new DeltaBase(options, callback);
}

/**
 * Expose constructor.
 */
module.exports.DeltaBase = DeltaBase;

// TODO: There is a potential error at a certain scale if file operations are not fully
// flushed before starting a next test. For full robustness need to track
// all file handles and flush the DB using fsync.
