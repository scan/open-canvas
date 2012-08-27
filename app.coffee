express = require 'express'
stylus = require 'stylus'
_s = require 'underscore.string'

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

randHex = ->
    t = (Math.floor Math.random() * 192)
    p = if t < 16 then '0' else ''
    "#{p}#{t.toString 16}"

clients = []
num = 0

io.sockets.on 'connection', (socket) ->
    colour = "##{randHex()}#{randHex()}#{randHex()}"
    name = "user#{++num}"

    clients[socket.id] =
        colour: colour
        name: name

    socket.emit 'ready', colour: colour, name: name, clients: clients
    socket.broadcast.emit 'joined', colour: colour, name: name

    socket.on 'mousemove', (data) ->
        data.colour = colour
        socket.broadcast.emit 'moving',
            colour: colour
            id: socket.id
            position:
                x: data.x or 0
                y: data.y or 0

    socket.on 'msg', (data) ->
        socket.emit 'msg', "<span style=\"color:#{colour};font-style:italic\">#{name}</span>: #{_s.escapeHTML data}"
        socket.broadcast.emit 'msg', "<span style=\"color:#{colour};font-style:italic\">#{name}</span>: #{_s.escapeHTML data}"

    socket.on 'disconnect', ->
        delete clients[socket.id]
        socket.broadcast.emit 'left', colour: colour, name: name, id: socket.id

    socket.on 'drawn', (data) ->
        socket.broadcast.emit 'drawn',
            position:
                x: data.position.x or 0
                y: data.position.y or 0
            tool: data.tool or 'pencil'
            colour: data.colour or '#000'
            size: data.size or 1
