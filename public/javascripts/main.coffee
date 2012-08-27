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
        tool = 'pencil'
        size = 1

        window.drawing = off

        clients = []
        socket = io.connect()

        socket.on 'ready', (d) ->
            colour = d.colour
            ($ '#chatlist').prepend "<li><i>You joined as <span style=\"color:#{d.colour}\">#{d.name}</span>.</i></li>"
            clients = d.clients

            socket.on 'moving', (data) ->
                unless data.id of clients
                    cursors[data.id] = ($ '<div/>', class: 'cursor').appendTo '#cursors'
                cursors[data.id].css
                    'left': data.position.x
                    'top': data.position.y
                clients[data.id] = data
                clients[data.id].updated = $.now()

            $canvas.on 'mousedown', (e) ->
                e.preventDefault()
                window.drawing = on
                instructions.fadeOut()
                false

            $doc.bind 'mouseup mouseleave', ->
                window.drawing = off
                true

            lastEmit = $.now()
            $canvas.on 'mousemove', (e) ->
                if $.now() - lastEmit > 30
                    socket.emit 'mousemove',
                        x: e.pageX
                        y: e.pageY
                    lastEmit = $.now()
                if drawing
                    data =
                        position:
                            x: e.pageX
                            y: e.pageY
                        tool: tool
                        size: size
                        colour: colour
                    draw data
                    socket.emit 'drawn', data

            draw = (data) ->
                ctx.beginPath()
                if data.tool is 'eraser'
                    ctx.clearRect data.position.x - (size / 2), data.position.y - (size / 2), size, size
                else
                    switch data.tool
                        when 'pencil'
                            ctx.arc data.position.x, data.position.y, data.size, 0, 2 * Math.PI, no
                    ctx.fillStyle = data.colour
                    ctx.fill()
                    ctx.lineWidth = 1
                    ctx.strokeStyle = data.colour
                    ctx.stroke()

            socket.on 'drawn', draw

            ($ '#chatform').submit (e) ->
                e.preventDefault()

                socket.emit 'msg', ($ '#chattext').val()
                ($ '#chattext').val('').focus()

                false

            socket.on 'msg', (d) ->
                ($ '#chatlist').prepend "<li>#{d}</li>"
            socket.on 'joined', (d) ->
                ($ '#chatlist').prepend "<li><i><span style=\"color:#{d.colour}\">#{d.name}</span> joined.</i></li>"
                clients[d.id] =
                    name: d.name
                    colour: d.colour
            socket.on 'left', (d) ->
                ($ '#chatlist').prepend "<li><i><span style=\"color:#{d.colour}\">#{d.name}</span> left.</i></li>"
                cursors[d.id].remove()
                delete clients[d.id]
                delete cursors[d.id]

            ($ '#penciltool').click (e) ->
                e.preventDefault()
                tool = 'pencil'
                false
            ($ '#erasertool').click (e) ->
                e.preventDefault()
                tool = 'eraser'
                false
            ($ '#toolsize').change ->
                size = (parseInt $(@).val()) or 1
                ($ '#sizespan').text size.toString()
