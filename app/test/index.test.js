const assert = require('assert');
describe('index.js', function() {
  const index = require("./../src/index.js")
  describe('#handler()', function() {
    it('should OK', function() {
      index.handler({}, {}, (err, res) => {
          assert.equal(res.statusCode, 200)
      })
    });
  });
});