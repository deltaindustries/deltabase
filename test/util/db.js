var testDbPath = "testdb";
var rmdir = require('rimraf');

exports.init = function initTestDb(done) {
  testDoc = {
    foo: 'bar'
  };
  rmdir(testDbPath, function(err,result){
    db = deltabase({
      path: testDbPath
    }, done);
  });
};
