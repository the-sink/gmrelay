const fs = require('fs');
const http = require('http');
var WebSocketServer = require('websocket').server;
const Discord = require('discord.js');

// Prepare Discord client and pull config file

const client = new Discord.Client({intents: [Discord.Intents.FLAGS.GUILDS, Discord.Intents.FLAGS.GUILD_MESSAGES]});

let config = {};

if (fs.existsSync('config.json')) {
    config = JSON.parse(fs.readFileSync('config.json'));
} else {
    console.error("A config.json file is required!");
    process.exit();
}

// Create server and websocket, bind to events

let server = http.createServer(function(request, response) {
    console.log("received request");
    response.writeHead(404);
    response.end();
});
server.listen(config.serverPort, function(){
    console.log("Server listening");
});

let websocket = new WebSocketServer({
    httpServer: server,
    autoAcceptConnections: false
});

websocket.on("request", function(request){
    var connection = request.accept(null, request.origin);
    console.log("connected");

    connection.on('message', function(message){
        let content = message.utf8Data.match(new RegExp("\-name:(?<name>.*)\-text:(?<text>.*)"))
        if (content){
            console.log(content.groups['name']);
            console.log(content.groups['text']);
            client.webhook.send({
                content: content.groups['text'],
                username: content.groups['name']
            })
        }
    });

    client.on('messageCreate', (message) => {
        if (message.channel.id == config.channelId && !message.author.bot){
            let response = "name:" + message.member.displayName + "\ncolor:" + message.member.displayHexColor + "\ntext:" + message.content;
            connection.send(response);
            console.log(response);
        }
    });
});

client.on('ready', () => {
    console.log("Discord bot online");

    client.webhook = new Discord.WebhookClient({url: config.webhookUrl});
});

process.on('SIGINT', function(){
    client.destroy();
    websocket.shutDown();
    process.exit();
});

client.login(config.botToken);