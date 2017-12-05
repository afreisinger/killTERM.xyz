var LambdaForwarder = require("aws-lambda-ses-forwarder");
// 1
exports.handler = function(event, context, callback) {
  // See aws-lambda-ses-forwarder/index.js for all options.
  var overrides = {
    config: {
      fromEmail: "noreply@killTERM.xyz",
      emailBucket: "killterm.xyz-ses-emails",
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
