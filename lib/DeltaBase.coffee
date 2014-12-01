###
A simple flat-file document store, awesome for local dev.

Some aims:

 - API similarity to existing nosql DBs (a long-term goal might be an indentical API to one of the leading ones)
 - Parallel scalability for multiple local processes
 - Horizontal scalability for cloud apps (tricky...)
 - Expost REST interface via ExpressJS
###

fs = require('fs')
path = require('path')
_ = require('lodash')

create = (options = {})->
  dbpath = options.path ? 'data'
  docspath = path.join(dbpath, 'docs')
  indexpath = path.join(dbpath, 'indices')
  # Initialize a new database
  # 
  if !fs.existsSync(dbpath)
    fs.mkdirSync(dbpath)
    fs.mkdirSync(docspath)
    fs.mkdirSync(indexpath)

  # Primary index of doc ids
  index = {}

  # Secondary indices which get generated and cached (in files in indexpath)
  indices = {}
  ###
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
  ###

  # Spider thru the indicies 
  spiderIndicies = (crits, doc)->
    for crit, partitions of crits
      # Check doc's current value for the criteria
      # TODO: toString() is a slightly naive case which will work for simple
      # field values but gets us in trouble if dealing with more complex objects
      critVal = doc[crit].toString()
      for key,val of partitions
        if key != critVal
          continue
        # So the value at this point could either be an array of results
        # (in which case we've found an index to which to add the doc) or could
        # be further criteria for a deeply nested index; not sure if this is truly
        # necessary but with large datasets probably don't want to be intersecting huge
        # arrays from two different filter criteria.
        if _.isArray(val)
          val.push(doc)
        else
          # Recursive search
          spiderIndicies(val, doc)

  addToIndex = (id, doc)->
    index[id] = doc
    spiderIndicies(indices)

  queryApi = (db)->

  filePathForDoc = (id, doc, callback)->
    if _.isFunction(doc)
      callback = doc

    docpath = path.join(docspath, id)
    rev = 1
    filepath = path.join(docpath, rev + ".json")

    # Check if document folder exists and create if not
    # TODO: Start keeping a list of docpaths so don't have to perform this fs exists for every op
    # ... in fact only ever need to create the docpath with a 'set' op
    fs.exists docpath, (result)->
      if result
        return callback(null, filepath)
      fs.mkdir docpath, (err, result)->
        if err
          return callback(err)
        callback(null, filepath)

  db = 
    set: (id, doc, callback)->
      # Create a new document
      if !_.isString(id)
        return callback(new Error('Document id must be a string, got: ' + id + ' (' + typeof id + ')'))
      text = JSON.stringify(doc)
      $meta = 
        revision: 1
      filePathForDoc id, doc, (err, filePath)->
        if err
          return callback(err)
        $meta.filepath = filePath
        doc.$meta = $meta
        fs.exists filePath, (result)->
          if result
            return callback(new Error('Document already exists with id: "' + id + '"'))
          fs.writeFile filePath, text, (err)->
            if err
              return callback(err)
            addToIndex(id, doc)
            # TODO: Should result include more metadata about the item ... e.g. revision numbers ... file path ... etc.
            callback(null, doc)

    get: (id, callback)->
      if !_.isString(id)
        return callback(new Error('Document id must be a string, got: ' + id + ' (' + typeof id + ')'))
      if index[id]?
        return callback(null, index[id])
      # Otherwise try to load from fs
      # TODO: This results in folders being created for non-existent Ids, even though a document
      # isn't created.
      filePathForDoc id, (err, filePath)->
        if err
          return callback(err)
        fs.readFile filePath, (err, result)->
          if err
            return callback(err)
          # Parse result
          # TODO: Test for corrupt file behaviour, add try/catch
          doc = JSON.parse(result.toString())
          doc.$meta =
            revision: 1
            filepath: filePath
          # Store doc in indices
          addToIndex(id, doc)
          callback(null, doc)

    unset: (id, callback)->
      # Remove and unindex a document
    update: (id, updates, callback)->
      # Update some fields. Reindex the doc (remove then add back to index)

    query: (options)->
      # Construct an advanced query (chainable)

    lock: (id, callback)->
      # Get a lock on an object. Should be released as quickly as possible. This guarantees that
      # no other server will modify the doc while you are working with it. TODO: Could deep clone an instance
      # to ensure that not even another async process will modify fields unexpectedly. Maybe a "snapshot"
      # command could be used for this. The lesson is to only ever hold onto DB objects for as short a time
      # as possible!

  db

module.exports = create
