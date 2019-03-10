module.exports.handler = function(event, context, callback) {
    callback(null, {
      statusCode: '200',
      body: JSON.stringify({message: "OK"}),
      headers: {
        'Content-Type': 'application/json',
      },
    });
  };