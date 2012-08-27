(function() {

  $(function() {
    var $canvas, $doc, $win, clients, colour, ctx, instructions, size, socket, tool;
    if (!('getContext' in document.createElement('canvas'))) {
      return alert('Seems like your browser doesn\'t support an HTML5 canvas!');
    } else {
      ($('#chattext')).focus();
      $doc = $(document);
      $win = $(window);
      $canvas = $('#paper');
      ctx = $canvas[0].getContext('2d');
      instructions = $('#instructions');
      colour = '#000';
      tool = 'pencil';
      size = 1;
      window.drawing = false;
      clients = [];
      socket = io.connect();
      return socket.on('ready', function(d) {
        var draw, lastEmit;
        colour = d.colour;
        ($('#chatlist')).prepend("<li><i>You joined as <span style=\"color:" + d.colour + "\">" + d.name + "</span>.</i></li>");
        clients = d.clients;
        socket.on('moving', function(data) {
          if (!(data.id in clients)) {
            cursors[data.id] = ($('<div/>', {
              "class": 'cursor'
            })).appendTo('#cursors');
          }
          cursors[data.id].css({
            'left': data.position.x,
            'top': data.position.y
          });
          clients[data.id] = data;
          return clients[data.id].updated = $.now();
        });
        $canvas.on('mousedown', function(e) {
          e.preventDefault();
          window.drawing = true;
          instructions.fadeOut();
          return false;
        });
        $doc.bind('mouseup mouseleave', function() {
          return window.drawing = false;
        });
        lastEmit = $.now();
        $doc.on('mousemove', function(e) {
          var data;
          if ($.now() - lastEmit > 30) {
            socket.emit('mousemove', {
              x: e.pageX,
              y: e.pageY
            });
            lastEmit = $.now();
          }
          if (drawing) {
            data = {
              position: {
                x: e.pageX,
                y: e.pageY
              },
              tool: tool,
              size: size,
              colour: colour
            };
            draw(data);
            return socket.emit('drawn', data);
          }
        });
        draw = function(data) {
          console.log({
            drawing: true,
            data: data
          });
          ctx.beginPath();
          switch (data.tool) {
            case 'pencil':
              ctx.arc(data.position.x, data.position.y, data.size, 0, 2 * Math.PI, false);
          }
          ctx.fillStyle = data.colour;
          ctx.fill();
          ctx.lineWidth = 1;
          ctx.strokeStyle = data.colour;
          return ctx.stroke();
        };
        socket.on('drawn', draw);
        ($('#chatform')).submit(function(e) {
          e.preventDefault();
          socket.emit('msg', ($('#chattext')).val());
          ($('#chattext')).val('').focus();
          return false;
        });
        socket.on('msg', function(d) {
          return ($('#chatlist')).prepend("<li>" + d + "</li>");
        });
        socket.on('joined', function(d) {
          ($('#chatlist')).prepend("<li><i><span style=\"color:" + d.colour + "\">" + d.name + "</span> joined.</i></li>");
          return clients[d.id] = {
            name: d.name,
            colour: d.colour
          };
        });
        return socket.on('left', function(d) {
          ($('#chatlist')).prepend("<li><i><span style=\"color:" + d.colour + "\">" + d.name + "</span> left.</i></li>");
          cursors[d.id].remove();
          delete clients[d.id];
          return delete cursors[d.id];
        });
      });
    }
  });

}).call(this);
