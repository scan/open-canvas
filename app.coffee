express = require 'express'
stylus = require 'stylus'

module.exports = app = express.createServer()

io = (require 'socket.io').listen app

PUBLIC_DIR = "#{__dirname}/public"

app.configure ->
    app.set 'views', "#{__dirname}/views"
    app.set 'view engine', 'jade'
    app.set 'view options', layout: no

    app.use express.compiler src: PUBLIC_DIR, enable: ['coffeescript']

    app.use stylus.middleware
        src: PUBLIC_DIR
        dest: PUBLIC_DIR
        compile: (str, path) ->
            stylus(str).set('filename', path).set('compress', yes).use (require 'nib')()

    app.use express.static PUBLIC_DIR
    app.use express.favicon()
    app.use express.compress()
    app.use app.router

app.configure 'development', ->
    app.use express.errorHandler
        showStack: yes
        dumpExceptions: yes

app.get '/', (req, res) ->
    res.render 'index'

app.get "*", (req, res) ->
    res.send 404, error: 'Not Found'

PORT = process.env["app_port"] or process.env.PORT or 8080
app.listen PORT, ->
    console.log ":: nodester :: \n\nApp listening on port #{@address().port}"

randHex = -> (Math.floor Math.random() * 256).toString 16

num = 0

io.sockets.on 'connection', (socket) ->
    colour = "##{randHex()}#{randHex()}#{randHex()}"
    name = "user#{++num}"

    socket.emit 'ready', colour: colour, name: name

    socket.on 'mousemove', (data) ->
        socket.broadcast.emit 'moving', data

    socket.on 'msg', (data) ->
        console.log data: data
        socket.emit 'msg', "<span style=\"color:#{colour};font-style:italic\">#{name}</span>: #{data}"
        socket.broadcast.emit 'msg', "<span style=\"color:#{colour};font-style:italic\">#{name}</span>: #{data}"
