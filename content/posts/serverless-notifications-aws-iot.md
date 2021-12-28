+++
title = "Real Time Serverless Notifications with AWS IoT"
date = "2017-08-26T11:11:13Z"
author = "Mike Rosack"
authorTwitter = "mike_rosack" #do not include @
tags = ["serverless", "aws", "lambda", "iot", "pydt"]
keywords = ["", ""]
readingTime = true
aliases = ["/2017/08/26/real-time-serverless-notifications-with-aws-iot"]
+++

A big downside of current "Serverless" architectures is, well, you don't have a server!   Because of this, some things that we take for granted in web applications today are hard to do in a Serverless model - take real time notifications for example.   Usually you'd use [SignalR](https://www.asp.net/signalr), [Socket.IO](https://socket.io/), or some other framework to help you set up and use websocket connections, but those frameworks require a long-lived connection to a server.   You could use a technique like long polling in the serverless model, but serverless options charge by the second, and every second you've got the connection open doing nothing you're being charged for it.   So what to do?

I had this dilemma with [PYDT's](https://www.playyourdamnturn.com/) desktop client - it needs to know when a new turn is available for the user to play, but the only way to check for updated turns in a standard serverless model is dumb polling.   Unfortunately, the cost of AWS API Gateway (which serves your requests for Lambda) is $4/million requests, so that was going to be way too expensive if we polled once a minute (46K requests a month per user, assuming a user's PC is always on).   What I originally ended up doing was caching game state to S3, and polling S3 instead of the API, which is an order of magnitude cheaper (that same $4 gets you about 10 million requests in S3).

That worked fine, but it was hacky, and obviously websockets/push notifications were made for scenarios like this.   So what do we do?

[AWS IoT](https://aws.amazon.com/iot) to the rescue!   While it's not really designed for this purpose, it exposes an [MQTT](http://mqtt.org/) server that you can use to talk to "devices" out on the internet, but for our purposes our devices are just going to be normal web browsers.   Let's walk through the code I used to get this set up...

{{% class disclaimer %}}
DISCLAIMER: The PYDT use case is very simple - no security is required, because no one will care if the messages we're sending ("it's your turn") are intercepted by a user that wasn't the intended receiver.   Adding security complicates this scenario a lot, but this is a good example of what's possible!
{{% /class %}}

At it's most basic level, AWS IoT exposes an MQTT endpoint that you can use for pub/sub of messages.   There's a lot of other cool functionality in there, but for our purposes that's all we care about.   We want each user to only get messages when there's a new turn in one of their games, but nobody else's, so each user will need their own topic to subscribe to.   In PYDT, that looks like **/pydt/ENVIRONMENT/user/STEAM_ID/gameupdate**, where ENVIRONMENT is dev or prod, and STEAM_ID is, well, the user's Steam ID.

## Client Side

On the client, we're using [aws-iot-device-sdk-js](https://github.com/aws/aws-iot-device-sdk-js), a library that wraps an MQTT client and adds additional AWS IoT-specific functionality.   It's not too hard to set things up, here's all the code it takes ([starting at line 114 here](https://github.com/aws/aws-iot-device-sdk-js)):

{{< code language="javascript" >}}
  configureIot() {
    const env = PYDT_CONFIG.PROD ? 'prod' : 'dev';
    const topic = `/pydt/${env}/user/${this.profile.steamid}/gameupdate`;

    this.iotDevice = awsIot.device({
      region: 'us-east-1',
      protocol: 'wss',
      keepalive: 600,
      accessKeyId: PYDT_CONFIG.IOT_CLIENT_ACCESS_KEY,
      secretKey: PYDT_CONFIG.IOT_CLIENT_SECRET_KEY,
      host: 'a21s639tnrshxf.iot.us-east-1.amazonaws.com'
    });

    this.iotDevice.on('connect', () => {
      this.iotDevice.subscribe(topic);
    });

    this.iotDevice.on('error', err => {
      console.log('IoT error...', err);
    });

    this.iotDevice.on('message', (recTopic, message) => {
      console.log('received message from topic ', recTopic);
      if (recTopic === topic) {
        this.loadGames();
      }
    });
  }
{{< /code >}}


A couple things to note here:

* We set the keepalive to 600 seconds.   By default, I think the keepalive is 60, which means the client will ping the server once a minute to make sure the connection is open.   AWS doesn't make a big deal out of this in their documentation, but **YOU GET CHARGED FOR EVERY PING**, and at $5/million messages that's even worse than our dumb polling pricing!   On a desktop computer, the connection should be fairly stable anyway, so only pinging once every 10 minutes isn't that big of a deal (and I might even make that higher someday).

* The access and secret keys are set up to only have permissions to subscribe to a topic and receive messages, so a malicious user wouldn't be able to take those keys and publish messages to everyone.

Easy, huh?   That's all it takes, and every time the server sends us a message we'll receive it in the message callback!

## Server Side

The server side is even easier, believe it or not.   We just use the IotData class in the aws-sdk ([see the userTurnNotification handler in the API](https://github.com/pydt/api/blob/00a352b0b845b8ce097290142d122458c5046817/functions/sns/userTurnNotification.js)):

{{< code language="javascript" >}}
const iotData = new AWS.IotData({endpoint: 'a21s639tnrshxf.iot.us-east-1.amazonaws.com'});

function notifyUserClient(user) {
  return iotData.publish({
    topic: `/pydt/${process.env.SERVERLESS_STAGE}/user/${user.steamId}/gameupdate`,
    payload: "Hello!",
    qos: 0
  }).promise();
}
{{< /code >}}

That's it - all we have to do is point the client at the correct endpoint, and publish a message to the topic for the appropriate user!   Notice the qos setting of 0 - that just means fire and forget.   If the client is online and ready to receive the message they'll get it, if not, no big deal, just throw the message away.

## It's a bit anticlimactic...

Yeah, that's really all it took to get push notifications working in PYDT!   If you do need to authenticate the users you're sending messages to this obviously gets quite a bit more complicated, [here's a good blog post](https://serverless.com/blog/serverless-notifications-on-aws/) on serverless.com that describes the extra steps you'd need to do.   Good luck!