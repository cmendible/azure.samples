var HttpTransportType = require('@microsoft/signalr');
var express = require('express');

const app = express();
const port = 3000;
app.get('/', (req, res) => {
  res.sendStatus(200);
});
app.listen(port, err => {
  if (err) {
    return console.error(err);
  }
  return console.log(`server is listening on ${port}`);
});

var signalR = require('@microsoft/signalr');

const username = new Date().getTime();

const AGIC_IP = process.env.AGIC_IP;

const connection = new signalR.HubConnectionBuilder()
  .withUrl(`http://${AGIC_IP}/default`, HttpTransportType.WebSockets)
  .configureLogging(signalR.LogLevel.Debug) //https://docs.microsoft.com/en-us/aspnet/core/signalr/javascript-client?view=aspnetcore-5.0
  .withAutomaticReconnect()
  .build();

connection.on("Send", (message) => {
  console.log(message);
});

async function start() {
  try {
    await connection.start();
    console.log("SignalR Connected.");
  } catch (err) {
    console.log(err);
  }
};

// Start the connection.
start();