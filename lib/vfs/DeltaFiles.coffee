###
A virtual file system for serving up files to the client.
###

# TODO: Client-side files will be slightly overridden but very similar API.
# Additionally, files can be marked as server-only.

class DeltaFiles
  files: {}
  tree: {}
  ready: false
  queue: []

  constructor: ()->
    @files = {}
    @tree = {}
    @queue = []

  get: (path, callback)->
    if @ready?
      callback(null, @files[path])
    @queue.push ()=>
      callback(null, @files[path])

  ready: ()->
    @ready = true
    for q in @queue
      q()
    @queue = []

  add: (path, file)->
    @files[path] = file

module.exports = ()->DeltaFiles
