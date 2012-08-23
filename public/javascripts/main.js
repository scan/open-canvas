(function() {

  $(function() {
    var $canvas, $doc, $win, clients, ctx, cursors, drawLine, id, instructions, lastEmit, prev, socket;
    if (!('getContext' in document.createElement('canvas'))) {
      return alert('Seems like your browser doesn\'t support an HTML5 canvas!');
    } else {
      ($('#chattext')).focus();
      $doc = $(document);
      $win = $(window);
      $canvas = $('#paper');
      ctx = $canvas[0].getContext('2d');
      instructions = $('#instructions');
      id = Math.round($.now() * Math.random());
      window.drawing = false;
      clients = [];
      cursors = [];
      socket = io.connect();
      socket.on('moving', function(data) {
        if (!(data.id in clients)) {
          cursors[data.id] = ($('<div/>', {
            "class": 'cursor'
          })).appendTo('#cursors');
        }
        cursors[data.id].css({
          'left': data.x,
          'top': data.y
        });
        if (data.drawing && clients[data.id]) {
          drawLine(clients[data.id].x, clients[data.id].y, data.x, data.y);
        }
        clients[data.id] = data;
        return clients[data.id].updated = $.now();
      });
      prev = {};
      $canvas.on('mousedown', function(e) {
        e.preventDefault();
        window.drawing = true;
        prev.x = e.pageX;
        prev.y = e.pageY;
        instructions.fadeOut();
        return false;
      });
      $doc.bind('mouseup mouseleave', function() {
        return window.drawing = false;
      });
      lastEmit = $.now();
      $doc.on('mousemove', function(e) {
        if ($.now() - lastEmit > 30) {
          socket.emit('mousemove', {
            x: e.pageX,
            y: e.pageY,
            drawing: drawing,
            id: id
          });
          lastEmit = $.now();
        }
        if (drawing) {
          drawLine(prev.x, prev.y, e.pageX, e.pageY);
          prev.x = e.pageX;
          return prev.y = e.pageY;
        }
      });
      setInterval((function() {
        var ident;
        for (ident in clients) {
          if ($.now() - clients[ident].updated > 10000) {
            cursors[ident].remove();
            delete clients[ident];
            delete cursors[ident];
          }
        }
        return null;
      }), 10000);
      drawLine = function(fromx, fromy, tox, toy) {
        ctx.moveTo(fromx, fromy);
        ctx.lineTo(tox, toy);
        return ctx.stroke();
      };
      ($('#chatform')).submit(function(e) {
        e.preventDefault();
        socket.emit('msg', ($('#chattext')).val());
        ($('#chattext')).val('').focus();
        return false;
      });
      return socket.on('msg', function(d) {
        return ($('#chatlist')).prepend("<li>" + d + "</li>");
      });
    }
  });

}).call(this);
