# AWS SES email forwarding

A terraform module for setting up SES and the [AWS Lambda SES Email Forwarder](https://github.com/arithmetric/aws-lambda-ses-forwarder).


## Manual steps ##
You must establish a verified email address for SES to send forwarded emails to.  This can be done via [the AWS SES Console](https://console.aws.amazon.com/ses) or using the cli:

```
aws ses verify-email-identity --email-address <your@real.email.address>
```

Check your inbox for a message with the subject containing *Amazon Web Services – Email Address Verification Request in region ...* and click on the verification link provided.

See the [AWS SES Developer Guide](https://docs.aws.amazon.com/ses/latest/DeveloperGuide/verify-email-addresses.html) for more information.

## Configuration ##
Configuration is accomplished in the *lambda/index.js* file. The one included is configured for the `killterm.xyz` domain. You **must** change it to work for your domain.
