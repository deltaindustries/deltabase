DeltaBase
=========

A NoSQL database (living on the filesystem), for node.js.

Built for testability and developer experience.

Further plans include an ODM layer, client API (as Connect middleware), and an AngularJS client layer.

Current features (at 0.0.10):

  - A key value document store supporting JSON objects
  - Each document is stored in the filesystem as a .json file
  - Pure Javascript and extremely light on dependencies
  - Highly testable due to avoidance of global or static state
  - Teardown is as simple as deleting a folder
  - Basic CRUD operations are supported and tested

Currently this is not recommended for a production deployment, but the aim is to fairly rapidly
have something that could be used in production for a smallish (single-server) website. The roadmap
does plan for eventual high scalability however.

Notes on Performance and Scalability
------------------------------------

Right now the development focus is on simplicity of development and testability. Performance relies
heavily on filesystem performance. Which, luckily, is something that hardware and OS manufacturers
have been optimising for many many years. Running locally with a small database this is extremely
performant compared to a full-blown database but it has yet to be seen how this would pan out with
a very large instance. Queries will be fairly slow until secondary indexes are implemented, which
is planned for the 0.1.0 release. See roadmap for more details.

Currently there is NO provision for horizontal scalability. You could rig something up 'simply' by
syncing filesystems and ensuring that all writes go to the authoritative server. See the roadmap
for plans in this area.

Running the Tests
-----------------

Prior to first run, Mocha is required:

  npm install -g mocha

To run tests:

  npm test

User Guide
----------

Add the library to your node.js project:

  npm install --save deltabase

To create or open a database in a folder called 'mydbpath' in your project root:

  var deltabase = require('deltabase');
  var db = deltabase({ path: 'mydbpath' });

The deltabase constructor accepts a second callback parameter which will be fired
when the database is ready. Currently this is negligible but operations *may* fail
before this time.

The API methods described below are not all implemented yet but will be available
very early.

### Storing a document

Use the set method to store a document. Throws an error if the key already exists.

  db.set('foo', 'bar', function(err, result){
    if (err) throw(err);
    // result is the document
    console.log(result);
  });

### Retrieving a document

Gets a stored document. Returns an error if the document doesn't exist. It is recommended
to use exists(...) to actually check for document existence since an error could indicate
another problem, e.g. system problems.

  db.get('foo', function(err, result){
    if (err) throw(err);
    console.log(result);
    // 'bar'
  });

Alternately, a list of keys may be provided as an array to return several documents
at once.

### Check for document existence

  db.exists('foo', function(err, result){
    if(!result)
      panic();
  });

### Updating a document

The update method will overwrite or add new fields to an existing document.

  db.update('module', { foo: 'bar' }, function(err, result){
    if (err) throw(err);
    db.update('test', { bar: 'baz' }, function(err, result){
      if (err) throw(err);
      console.log(result.foo); // 'bar'
      console.log(result.bar); // 'baz'
    });
  });

### Removing a document

Will throw an error if the document doesn't exist.

  db.unset('foo', function(err, result) {
    if (err) throw(err);
    console.log(result); // null
  });

### Listing documents

Lists all documents in the store and returns as an array. Not very practical but until the next
release this is the only way to perform any queries.

  db.list(function(err, results) {
    if (err) throw(err);
    for (i in results) {
      console.log(results[i]);
    }
  });

### Querying for documents

Very important note: not implemented, but the following serves as a preview of the eventual API.

Important note: this can get very slow since it involves reading every single document.
If all documents have been read already and therefore cached into memory then it will still
be pretty fast, at least with a small database. Secondary indexes and a more advanced querying
API will eventually be implemented to allow fast querying over larger datasets.

An optional Javascript indexing function is supplied to match documents fo returning. Right now
this is no faster than filtering the entire database, but once secondary indexes are implemented
an index will be automatically generated to speed up the query.

  db.query(function(key, doc){
    return (doc.foo === 'bar');
  }, function(err,results){
    for (bar in results) {
      console.log(bar.name); // ...
    }
  });

Additional query patterns will eventually be provided to cover a wide range of use cases
in an optimised fashion.

For instance; reading keys is expected to be quicker than loading entire documents, since this
just involves a call to readdir. If keys are formatted to contain enough information to filter a
set of results, then a call like this would be significantly faster:

  db.keys(function(key){
    return (key.indexOf('log_') === 0);
  }, function(err,results){
    // only log records are loaded from disk
  });

Furthermore a row-by-row streaming implementation could save a number of cycles. Consider a paging
solution as follows to read comments on a blog post with id '123':

  var page = 3;
  var pageSize = 10;
  var cursor = 0;
  db.streamKeys(function(key){
    var result = (++cursor >= page*pageSize && key.indexOf('comment_blogpost123_') === 0));
    return result;    
  }, function(key, doc, bail){
    if (cursor >= pageSize * (page + 1))
      return bail();
    render(doc);
  });

### Client API

An eventual client library (which will communicate with the REST API Connect middleware) would
mirror the above API to ease code reuse.

Roadmap
-------

These are long-term goals of the project. The order of implementation may change somewhat
depending on what makes sense at the time.

0.1.0 - Secondary indexes implemented to allow fast querying

0.2.0 - ODM framework for object construction and management

0.3.0 - REST API implemented as Connect middleware over the ODM layer

0.4.0 - Granular permissions and validation over fields

0.5.0 - Document versioning and translations, concurrency

0.6.0 - Object references and collections in ODM layer

0.7.0 - Performance and functional improvements

0.8.0 - AngularJS integrations

0.9.0 - Scalability via server synchronisation, locking, watching

1.0.0 - Production readiness and API stabilisation

Some more things under consideration:

 - Atomic inc/dec operations and append for lists of strings

Changelog
---------

0.0.11 - Fixed error with initial keys load.
0.0.10 - Added list() method.
0.0.9 - Added update() method.
0.0.8 - Added exists() and unset() methods.
0.0.7 - First usable version with get/set operations only.

Website and Support
-------------------

This here is all I got. More soon.

License
-------

DeltaBase is released under the MIT license.
