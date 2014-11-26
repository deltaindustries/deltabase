module.exports = (module)->
  module.on('test', (e)->
    @passed = true
  )
