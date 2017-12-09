var LambdaForwarder = require("aws-lambda-ses-forwarder");
exports.handler = function(event, context, callback) {
  // See aws-lambda-ses-forwarder/index.js for all options.
  var overrides = {
    config: {
      fromEmail: "noreply@killTERM.xyz",
      emailBucket: "killterm.xyz-" + process.env.ZONE_UUID + "-ses-emails",
      emailKeyPrefix: "emails/",
      subjectPrefix: "[xyz] ",
      forwardMapping: {
        "@killterm.xyz": [
          "john+xyz@killterm.com"
        ]
      }
    }
  };
  LambdaForwarder.handler(event, context, callback, overrides);
};
