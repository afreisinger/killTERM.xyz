var LambdaForwarder = require("aws-lambda-ses-forwarder");
exports.handler = function(event, context, callback) {
  // See aws-lambda-ses-forwarder/index.js for all options.
  var overrides = {
    config: {
      fromEmail: "noreply@killTERM.xyz",
      emailBucket: process.env.S3_BUCKET,
      emailKeyPrefix: "emails/",
      subjectPrefix: "[xyz] ",
      forwardMapping: JSON.parse(process.env.FORWARD_MAPPING)
    }
  };
  LambdaForwarder.handler(event, context, callback, overrides);
};
