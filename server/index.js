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

    var messageListener = (message) => {
        if (message.channel.id == config.channelId && !message.author.bot){
            let data = {
                "name": message.member.displayName,
                "color": message.member.displayHexColor,
                "text": message.content
            }
            let response = JSON.stringify(data);
            connection.send(response);
            console.log(response);
        }
    };

    connection.on('message', function(message){
        let data = JSON.parse(message.utf8Data);
        if (data){
            client.webhook.send({
                content: data.text,
                username: data.name
            })
        }
    });

    connection.on('error', function(err){
        console.warn("A websocket error has occured: " + err);
    });

    connection.on('close', function(){
        console.log("disconnected");
        client.removeListener('messageCreate', messageListener);
    });

    client.on('messageCreate', messageListener);
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