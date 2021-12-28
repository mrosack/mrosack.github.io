---
title: "Play Your Damn Turn"
aliases: ["/portfolio/pydt"]
---

{{< image src="/img/pydt.jpg" alt="Mike" position="right" style="width: 200px; margin-left: 10px; float:right; border-radius: 8px;" >}}

**Play Your Damn Turn** adds asynchronous support (play by email) to Civilization 6's hotseat multiplayer mode, taking care of the drudgery of passing save files around for you.  Later, it expanded to support Civ 5, Beyond Earth and Old World.  A desktop client is provided to download turns, put them in the appropriate location, and automatically send them to the next player after the turn is complete.  If you love playing Civ, go check it out at https://www.playyourdamnturn.com!

Source code is available at https://github.com/pydt

### Technologies Used:

* Full Stack Typescript
* [Angular](https://angular.io/) UI on both web and client
* [Electron](https://www.electronjs.org/) desktop client
* API backend hosted in [AWS Lambda](https://aws.amazon.com/lambda) using the [Serverless Framework](https://serverless.com/)
* [DynamoDB](https://aws.amazon.com/dynamodb) data store