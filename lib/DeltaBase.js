/**
 * Module dependencies.
 */
var fs = require('fs');
var path = require('path');
var _ = require('lodash');

create = function(options) {
  var addToIndex, db, dbpath, docspath, filePathForDoc, index, indexpath, indices, queryApi, spiderIndicies, _ref;
  if (options == null) {
    options = {};
  }
  dbpath = (_ref = options.path) != null ? _ref : 'data';
  docspath = path.join(dbpath, 'docs');
  indexpath = path.join(dbpath, 'indices');
  if (!fs.existsSync(dbpath)) {
    fs.mkdirSync(dbpath);
    fs.mkdirSync(docspath);
    fs.mkdirSync(indexpath);
  }
  index = {};
  indices = {};

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
  
  TODO: Extract indices out to a separate component for testing
   */
  spiderIndicies = function(crits, doc) {
    var crit, critVal, key, partitions, val, _results;
    _results = [];
    for (crit in crits) {
      partitions = crits[crit];
      critVal = doc[crit].toString();
      _results.push((function() {
        var _results1;
        _results1 = [];
        for (key in partitions) {
          val = partitions[key];
          if (key !== critVal) {
            continue;
          }
          if (_.isArray(val)) {
            _results1.push(val.push(doc));
          } else {
            _results1.push(spiderIndicies(val, doc));
          }
        }
        return _results1;
      })());
    }
    return _results;
  };
  addToIndex = function(id, doc) {
    index[id] = doc;
    return spiderIndicies(indices);
  };
  queryApi = function(db) {};
  filePathForDoc = function(id, doc, callback) {
    var docpath, filepath, rev;
    if (_.isFunction(doc)) {
      callback = doc;
    }
    docpath = path.join(docspath, id);
    rev = 1;
    filepath = path.join(docpath, rev + ".json");
    return fs.exists(docpath, function(result) {
      if (result) {
        return callback(null, filepath);
      }
      return fs.mkdir(docpath, function(err, result) {
        if (err) {
          return callback(err);
        }
        return callback(null, filepath);
      });
    });
  };
  db = {
    set: function(id, doc, callback) {
      var $meta, text;
      if (!_.isString(id)) {
        return callback(new Error('Document id must be a string, got: ' + id + ' (' + typeof id + ')'));
      }
      text = JSON.stringify(doc);
      $meta = {
        revision: 1
      };
      return filePathForDoc(id, doc, function(err, filePath) {
        if (err) {
          return callback(err);
        }
        $meta.filepath = filePath;
        doc.$meta = $meta;
        return fs.exists(filePath, function(result) {
          if (result) {
            return callback(new Error('Document already exists with id: "' + id + '"'));
          }
          return fs.writeFile(filePath, text, function(err) {
            if (err) {
              return callback(err);
            }
            addToIndex(id, doc);
            return callback(null, doc);
          });
        });
      });
    },
    get: function(id, callback) {
      if (!_.isString(id)) {
        return callback(new Error('Document id must be a string, got: ' + id + ' (' + typeof id + ')'));
      }
      if (index[id] != null) {
        return callback(null, index[id]);
      }
      return filePathForDoc(id, function(err, filePath) {
        if (err) {
          return callback(err);
        }
        return fs.readFile(filePath, function(err, result) {
          var doc;
          if (err) {
            return callback(err);
          }
          doc = JSON.parse(result.toString());
          doc.$meta = {
            revision: 1,
            filepath: filePath
          };
          addToIndex(id, doc);
          return callback(null, doc);
        });
      });
    },
    unset: function(id, callback) {},
    update: function(id, updates, callback) {},
    query: function(options) {},
    lock: function(id, callback) {}
  };
  return db;
};

module.exports = create;
