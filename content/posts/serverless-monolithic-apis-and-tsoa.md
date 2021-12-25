+++
title = "Serverless, \"Monolithic\" APIs, and TSOA"
date = "2017-03-20T13:30:50Z"
author = "Mike Rosack"
authorTwitter = "mike_rosack" #do not include @
cover = ""
tags = ["", ""]
keywords = ["", ""]
description = ""
showFullContent = false
readingTime = false
aliases = ["/2017/03/20/serverless-monolithic-apis-and-tsoa"]
+++

I've been geeking out quite a bit over Functions as a Service and the [Serverless Framework](https://serverless.com/) for the past year or so.  I wrote the backend for [Play Your Damn Turn](https://www.playyourdamnturn.com/) using it, and I think it's great for startup scenarios - you can write something and get it out there without having to worry about the costs of hosting, and if it suddenly becomes popular it's already built to scale.

That said, the Serverless Framework is still in it's infancy, and there aren't tons of best practices out there around using it. The Serverless team had a good blog post last year describing a couple possible approaches of how you could structure your application: [Serverless Code Patterns](https://serverless.com/blog/serverless-architecture-code-patterns/). In short, that article calls out 4 different possible approaches: Microservices, where every function maps to one API call; Services/Monolithic, where you group multiple API calls into one function; and Graph, where you just expose GraphQL from one function. For PYDT, I did things Microservices style, partly because I started writing PYDT before that article was written, and partly because all of the examples out there show how you to do things the Microservices way.

The Microservices pattern has a couple big downsides, though:

* **Cold Starts**: When a FaaS function gets called, what's really happening behind the scenes is a Docker container is spinning up, loading your code, and executing it.  That spin up process isn't free, and can take on the order of seconds to be ready for use.  However, if you call a function multiple times in short order, the container that the code originally ran in can be reused, removing the spin up cost.

* **CloudFormation Limits**: Serverless uses CloudFormation behind the scenes for AWS deployments.  Unfortunately, [CloudFormation has limits](http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cloudformation-limits.html), and there's [only so many functions you can add into a Serverless service](https://github.com/serverless/serverless/issues/2853) before you hit these limits.  I ran into this with PYDT, and I've had to resort to some ugly hacks to be able to fit more and more functions into the service.  There's not much they can do to fix this without getting into split CloudFormation stacks, and I think that's pretty far down on their list at the moment.

I've been kicking off a new project over the past couple of days, and because of those downsides I really didn't want to go down the Microservices path again.  Also, using Angular2 has really made me love Typescript, and I wanted to use it for the backend.  If I was going to do that, couldn't I get some cool benefits from having a strongly typed backend like auto-generation of Swagger schemas?

Why yes, yes I could!  I stumbled upon the [TSOA Framework](https://github.com/lukeautry/tsoa), which is suprisingly the only framework I could find that's using the benefits of Typescript to create an API backend that generates all the boilerplate for you.  I forked their startup project, started playing around, and this is the result: https://github.com/mrosack/tsoa-serverless-example.  It's still super raw, but even in its initial state it's got a lot of cool benefits over doing things the standard Javascript/Microservice way:

* **Automatically Generate swagger.json**: This is the big carrot that TSOA waves out in front of you, and I love it.  Keeping a swagger definition file up to date manually is a gigantic pain, and without eternal vigilance it can become useless pretty quickly.

* **Dependency Injection**: This is another thing that comes out of the box with TSOA.  It uses [InversifyJS](https://github.com/inversify/InversifyJS) for it's IOC container, and adds some sweet syntatic sugar to help hook up all the injections for you.

* **No Cold Starts/Limits**: The entire API is being deployed to a single Lambda function using [API Gateway Proxy/ANY](http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-create-api-as-simple-proxy-for-http.html), so you don't need to worry about cold starts for infrequently used functions or those pesky CloudFormation limits.

[Go take a look and let me know what you'll think!](https://github.com/mrosack/tsoa-serverless-example)  I'll be updating things as I get deeper into my own project, but I think the value is pretty clear even now and I'm really excited to keep playing with it!