express = require 'express'

module.exports = app = express.createServer()

io = (require 'socket.io').listen app

PUBLIC_DIR = "#{__dirname}/public"

app.configure ->
    app.set 'views', "#{__dirname}/views"
    app.set 'view engine', 'jade'
    app.set 'view options', layout: no

    app.use express.compiler src: PUBLIC_DIR, enable: ['coffeescript']
    app.use (require 'stylus').middleware src: PUBLIC_DIR, dest: PUBLIC_DIR
    app.use express.static PUBLIC_DIR
    app.use express.favicon()
    app.use app.router

app.get '/', (req, res) ->
    res.render 'index'

app.get "*", (req, res) ->
    res.send 404, error: 'Not Found'

PORT = process.env["app_port"] or 8080
app.listen PORT, ->
    console.log ":: nodester :: \n\nApp listening on port #{@address().port}"

io.sockets.on 'connection', (socket) ->
    socket.on 'mousemove', (data) ->
        socket.broadcast.emit 'moving', data
