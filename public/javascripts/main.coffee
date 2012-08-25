$ ->
    unless 'getContext' of document.createElement 'canvas'
        alert 'Seems like your browser doesn\'t support an HTML5 canvas!'
    else
        ($ '#chattext').focus()

        $doc = $ document
        $win = $ window
        $canvas = $ '#paper'
        ctx = $canvas[0].getContext '2d'
        instructions = $ '#instructions'
        colour = '#000'

        id = Math.round $.now() * Math.random()

        window.drawing = off

        clients = []
        cursors = []

        socket = io.connect()

        socket.on 'moving', (data) ->
            unless data.id of clients
                cursors[data.id] = ($ '<div/>', class: 'cursor').appendTo '#cursors'
            cursors[data.id].css
                'left': data.x
                'top': data.y
            if data.drawing and clients[data.id]
                drawLine clients[data.id].x, clients[data.id].y, data.x, data.y, data.colour
            clients[data.id] = data
            clients[data.id].updated = $.now()

        prev = {}

        $canvas.on 'mousedown', (e) ->
            e.preventDefault()
            window.drawing = on
            prev.x = e.pageX
            prev.y = e.pageY
            instructions.fadeOut()

            false
        $doc.bind 'mouseup mouseleave', ->
            window.drawing = off
        lastEmit = $.now()
        $doc.on 'mousemove', (e) ->
            if $.now() - lastEmit > 30
                socket.emit 'mousemove',
                    x: e.pageX
                    y: e.pageY
                    drawing: drawing
                    id: id
                lastEmit = $.now()
            if drawing
                drawLine prev.x, prev.y, e.pageX, e.pageY, colour
                prev.x = e.pageX
                prev.y = e.pageY
        setInterval (->
                for ident of clients
                    if $.now() - clients[ident].updated > 10000
                        cursors[ident].remove()
                        delete clients[ident]
                        delete cursors[ident]
                null
            ), 10000
        drawLine = (fromx, fromy, tox, toy, colour) ->
            ctx.beginPath()
            ctx.moveTo fromx, fromy
            ctx.lineTo tox, toy
            ctx.strokeStyle = colour
            ctx.stroke()

        ($ '#chatform').submit (e) ->
            e.preventDefault()

            socket.emit 'msg', ($ '#chattext').val()
            ($ '#chattext').val('').focus()

            false

        socket.on 'msg', (d) ->
            ($ '#chatlist').prepend "<li>#{d}</li>"
        socket.on 'joined', (d) ->
            ($ '#chatlist').prepend "<li><i><span style=\"color:#{d.colour}\">#{d.name}</span> joined.</i></li>"
        socket.on 'ready', (d) ->
            colour = d.colour
            ($ '#chatlist').prepend "<li><i>You joined as <span style=\"color:#{d.colour}\">#{d.name}</span>.</i></li>"