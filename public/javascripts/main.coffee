$ ->
    unless 'getContext' of document.createElement 'canvas'
        alert 'Seems like your browser doesn\'t support an HTML5 canvas!'
    else
        $doc = $ document
        $win = $ window
        $canvas = $ '#paper'
        ctx = $canvas[0].getContext '2d'
        instructions = $ '#instructions'

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
                drawLine clients[data.id].x, clients[data.id].y, data.x, data.y
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
                drawLine prev.x, prev.y, e.pageX, e.pageY
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
        drawLine = (fromx, fromy, tox, toy) ->
            ctx.moveTo fromx, fromy
            ctx.lineTo tox, toy
            ctx.stroke()
