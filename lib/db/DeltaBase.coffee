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

create = (options = {})->
  dbpath = options.path ? 'data'
  docpath = path.join(dbpath, 'docs')
  indexpath = path.join(dbpath, 'indices')
  # Initialize a new database
  # 
  if !fs.existsSync(dbpath)
    fs.mkdirSync(dbpath)
    fs.mkdirSync(docpath)
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
    spiderIndicies(indicies)

  queryApi = (db)->

  db = 
    get: (id, callback)->
    query: (options)->
      # Construct an advanced query (chainable)
    set: (id, doc, callback)->
      # Create a new document
    unset: (id, callback)->
      # Remove and unindex a document
    update: (id, updates, callback)->


  db

module.exports = create
